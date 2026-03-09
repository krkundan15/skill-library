from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from collections import Counter
from copy import deepcopy
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any


DEFAULT_RUN_ROOT = Path("outputs") / "skill-tests"
DEFAULT_MAX_ITERATIONS = 3
DEFAULT_FEEDBACK_TEMPLATE = {
    "approved": False,
    "score": 0,
    "summary": "Replace with a short human review summary.",
    "items": [
        {
            "severity": "high",
            "category": "quality",
            "issue": "Describe what was wrong.",
            "desired_change": "Describe the concrete change required in the next iteration.",
        }
    ],
}

CATEGORY_RECOMMENDATIONS = {
    "format": "Tighten output structure requirements in the skill and add an explicit formatting checklist.",
    "instruction": "Move non-negotiable instructions higher in the skill and make them more specific.",
    "quality": "Raise the acceptance bar in the skill with clearer examples of good vs bad output.",
    "validation": "Add or strengthen a validation step so weak outputs are caught before delivery.",
    "workflow": "Clarify the order of operations and promote mandatory checkpoints earlier in the workflow.",
}


@dataclass
class RunContext:
    config: dict[str, Any]
    run_dir: Path


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return slug or "case"


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: dict[str, Any] | list[Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def validate_config(config: dict[str, Any]) -> dict[str, Any]:
    if not config.get("skill_name"):
        raise ValueError("Config must include 'skill_name'.")
    cases = config.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("Config must include at least one case in 'cases'.")

    normalized = deepcopy(config)
    normalized["run_root"] = str(Path(config.get("run_root", DEFAULT_RUN_ROOT)))
    normalized["max_iterations"] = int(config.get("max_iterations", DEFAULT_MAX_ITERATIONS))

    for index, case in enumerate(cases, start=1):
        if not case.get("prompt"):
            raise ValueError(f"Case {index} is missing 'prompt'.")
        case.setdefault("id", f"case-{index:02d}")
        case.setdefault("success_criteria", [])
        case.setdefault("tags", [])

    return normalized


def load_config(config_path: Path) -> dict[str, Any]:
    return validate_config(read_json(config_path))


def create_run_dir(config: dict[str, Any], run_name: str | None = None) -> Path:
    base = Path(config["run_root"])
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    name = run_name or f"{slugify(config.get('name', config['skill_name']))}-{timestamp}"
    run_dir = base / name
    run_dir.mkdir(parents=True, exist_ok=False)
    return run_dir


def case_dir(run_dir: Path, case: dict[str, Any]) -> Path:
    return run_dir / "cases" / slugify(case["id"])


def iteration_dir(case_root: Path, iteration: int) -> Path:
    return case_root / f"iteration-{iteration:02d}"


def existing_iterations(case_root: Path) -> list[int]:
    iterations: list[int] = []
    for child in case_root.iterdir():
        if child.is_dir() and child.name.startswith("iteration-"):
            try:
                iterations.append(int(child.name.split("-")[-1]))
            except ValueError:
                continue
    return sorted(iterations)


def latest_iteration(case_root: Path) -> int | None:
    iterations = existing_iterations(case_root)
    return iterations[-1] if iterations else None


def latest_iteration_dir(case_root: Path) -> Path | None:
    current = latest_iteration(case_root)
    if current is None:
        return None
    return iteration_dir(case_root, current)


def feedback_template() -> dict[str, Any]:
    return deepcopy(DEFAULT_FEEDBACK_TEMPLATE)


def summarize_feedback_items(items: list[dict[str, Any]]) -> str:
    lines = []
    for item in items:
        severity = item.get("severity", "unspecified")
        category = item.get("category", "unspecified")
        issue = item.get("issue", "").strip()
        desired_change = item.get("desired_change", "").strip()
        lines.append(
            f"- [{severity}/{category}] {issue or 'No issue provided.'} "
            f"Fix: {desired_change or 'No desired change provided.'}"
        )
    return "\n".join(lines) or "- No detailed feedback items were provided."


def trim_text(content: str, limit: int = 2500) -> str:
    if len(content) <= limit:
        return content
    return content[:limit].rstrip() + "\n\n[Truncated for brevity.]"


def render_prompt(
    config: dict[str, Any],
    case: dict[str, Any],
    iteration: int,
    previous_output: str | None = None,
    feedback: dict[str, Any] | None = None,
) -> str:
    criteria = case.get("success_criteria") or []
    criteria_block = "\n".join(f"- {item}" for item in criteria) or "- No explicit success criteria were supplied."

    sections = [
        "# Skill Evaluation Prompt",
        f"Skill: {config['skill_name']}",
        f"Skill path: {config.get('skill_path', 'not provided')}",
        f"Case ID: {case['id']}",
        f"Iteration: {iteration}",
        "",
        "## Original User Prompt",
        case["prompt"].strip(),
        "",
        "## Success Criteria",
        criteria_block,
    ]

    if previous_output:
        sections.extend(
            [
                "",
                "## Previous Output",
                trim_text(previous_output.strip()),
            ]
        )

    if feedback:
        summary = str(feedback.get("summary", "")).strip() or "No summary provided."
        items = feedback.get("items") or []
        sections.extend(
            [
                "",
                "## Human Feedback Summary",
                summary,
                "",
                "## Human Feedback Items",
                summarize_feedback_items(items),
                "",
                "## Revision Requirements",
                "Address every feedback item. Keep what worked, fix what failed, and make the output stronger without changing the user's intent.",
            ]
        )

    sections.extend(
        [
            "",
            "## Response Instructions",
            "Produce the output for this skill test case. If this is a revision, explain briefly how each feedback item was addressed.",
        ]
    )
    return "\n".join(sections).strip() + "\n"


def generator_config(config: dict[str, Any]) -> dict[str, Any]:
    return config.get("generator") or {}


def has_generator(config: dict[str, Any]) -> bool:
    command = str(generator_config(config).get("command", "")).strip()
    return bool(command)


def command_context(
    config: dict[str, Any],
    run_dir: Path,
    case: dict[str, Any],
    iteration: int,
    prompt_file: Path,
    output_file: Path,
) -> dict[str, str]:
    return {
        "skill_name": config["skill_name"],
        "skill_path": str(config.get("skill_path", "")),
        "case_id": case["id"],
        "iteration": str(iteration),
        "prompt_file": str(prompt_file),
        "output_file": str(output_file),
        "run_dir": str(run_dir),
    }


def run_generator(
    config: dict[str, Any],
    run_dir: Path,
    case: dict[str, Any],
    iteration: int,
    prompt_file: Path,
    output_file: Path,
) -> dict[str, Any]:
    command_template = str(generator_config(config).get("command", "")).strip()
    if not command_template:
        return {"mode": "manual", "returncode": None}

    context = command_context(config, run_dir, case, iteration, prompt_file, output_file)
    command = command_template.format_map(context)
    use_shell = bool(generator_config(config).get("shell", True))
    env = os.environ.copy()
    env.update(
        {
            "SKILL_EVAL_PROMPT_FILE": str(prompt_file),
            "SKILL_EVAL_OUTPUT_FILE": str(output_file),
            "SKILL_EVAL_SKILL_NAME": config["skill_name"],
            "SKILL_EVAL_CASE_ID": case["id"],
            "SKILL_EVAL_ITERATION": str(iteration),
            "SKILL_EVAL_RUN_DIR": str(run_dir),
        }
    )

    completed = subprocess.run(
        command,
        shell=use_shell,
        capture_output=True,
        text=True,
        env=env,
        check=False,
    )
    stdout_path = output_file.with_name("stdout.txt")
    stderr_path = output_file.with_name("stderr.txt")
    write_text(stdout_path, completed.stdout or "")
    write_text(stderr_path, completed.stderr or "")

    if not output_file.exists():
        if completed.stdout.strip():
            write_text(output_file, completed.stdout)
        else:
            write_text(
                output_file,
                "Generator command completed without writing a model output. Replace this file with the generated output before review.\n",
            )

    return {
        "mode": "command",
        "command": command,
        "returncode": completed.returncode,
        "stdout_file": str(stdout_path),
        "stderr_file": str(stderr_path),
    }


def manual_output_placeholder() -> str:
    return (
        "No generator command is configured.\n"
        "Paste or replace this file with the skill output produced from the prompt in prompt.txt.\n"
    )


def write_iteration_files(
    ctx: RunContext,
    case: dict[str, Any],
    iteration: int,
    prompt: str,
) -> Path:
    case_root = case_dir(ctx.run_dir, case)
    current_dir = iteration_dir(case_root, iteration)
    current_dir.mkdir(parents=True, exist_ok=False)

    prompt_file = current_dir / "prompt.txt"
    output_file = current_dir / "output.md"
    feedback_template_file = current_dir / "feedback.template.json"
    meta_file = current_dir / "generation.meta.json"

    write_text(prompt_file, prompt)
    write_json(feedback_template_file, feedback_template())

    if has_generator(ctx.config):
        meta = run_generator(ctx.config, ctx.run_dir, case, iteration, prompt_file, output_file)
    else:
        write_text(output_file, manual_output_placeholder())
        meta = {"mode": "manual", "returncode": None}

    write_json(meta_file, meta)
    return current_dir


def load_feedback(current_dir: Path) -> dict[str, Any] | None:
    feedback_file = current_dir / "feedback.json"
    if not feedback_file.exists():
        return None
    return read_json(feedback_file)


def latest_feedback(case_root: Path) -> tuple[int, dict[str, Any]] | None:
    for iteration in reversed(existing_iterations(case_root)):
        current_dir = iteration_dir(case_root, iteration)
        feedback = load_feedback(current_dir)
        if feedback is not None:
            return iteration, feedback
    return None


def write_case_metadata(case_root: Path, case: dict[str, Any]) -> None:
    write_json(case_root / "case.json", case)


def init_run(config_path: Path, run_name: str | None = None) -> Path:
    config = load_config(config_path)
    run_dir = create_run_dir(config, run_name)
    ctx = RunContext(config=config, run_dir=run_dir)

    write_json(run_dir / "config.snapshot.json", config)
    for case in config["cases"]:
        case_root = case_dir(run_dir, case)
        case_root.mkdir(parents=True, exist_ok=True)
        write_case_metadata(case_root, case)
        prompt = render_prompt(config, case, iteration=1)
        write_iteration_files(ctx, case, iteration=1, prompt=prompt)

    summarize_run(run_dir)
    return run_dir


def build_next_iteration_prompt(config: dict[str, Any], case_root: Path, case: dict[str, Any]) -> tuple[int, str] | None:
    latest = latest_feedback(case_root)
    if latest is None:
        return None

    current_iteration, feedback = latest
    if bool(feedback.get("approved")):
        return None

    max_iterations = int(config["max_iterations"])
    next_iteration = current_iteration + 1
    if next_iteration > max_iterations:
        return None

    previous_output = (iteration_dir(case_root, current_iteration) / "output.md").read_text(encoding="utf-8")
    prompt = render_prompt(
        config,
        case,
        iteration=next_iteration,
        previous_output=previous_output,
        feedback=feedback,
    )
    return next_iteration, prompt


def load_run(run_dir: Path) -> RunContext:
    config = read_json(run_dir / "config.snapshot.json")
    return RunContext(config=config, run_dir=run_dir)


def advance_run(run_dir: Path) -> list[Path]:
    ctx = load_run(run_dir)
    created: list[Path] = []

    for case in ctx.config["cases"]:
        case_root = case_dir(run_dir, case)
        next_payload = build_next_iteration_prompt(ctx.config, case_root, case)
        if next_payload is None:
            continue

        next_iteration, prompt = next_payload
        next_dir = iteration_dir(case_root, next_iteration)
        if next_dir.exists():
            continue
        created.append(write_iteration_files(ctx, case, next_iteration, prompt))

    summarize_run(run_dir)
    return created


def normalize_issue(text: str) -> str:
    return " ".join(text.lower().split())


def summarize_run(run_dir: Path) -> Path:
    ctx = load_run(run_dir)
    statuses = []
    category_counts: Counter[str] = Counter()
    desired_change_counts: Counter[str] = Counter()

    for case in ctx.config["cases"]:
        case_root = case_dir(run_dir, case)
        latest = latest_feedback(case_root)
        if latest is None:
            statuses.append((case["id"], "awaiting review", 1, "No human feedback yet."))
            continue

        iteration, feedback = latest
        approved = bool(feedback.get("approved"))
        status = "approved" if approved else "needs revision"
        summary = str(feedback.get("summary", "")).strip() or "No summary provided."
        statuses.append((case["id"], status, iteration, summary))

        for item in feedback.get("items") or []:
            category = str(item.get("category", "uncategorized")).strip().lower() or "uncategorized"
            category_counts[category] += 1
            desired_change = normalize_issue(str(item.get("desired_change", "")).strip())
            if desired_change:
                desired_change_counts[desired_change] += 1

    lines = [
        "# Skill Feedback Loop Summary",
        "",
        f"Skill: {ctx.config['skill_name']}",
        f"Run directory: {run_dir}",
        "",
        "## Case Status",
    ]
    for case_id, status, iteration, summary in statuses:
        lines.append(f"- `{case_id}`: {status} after iteration {iteration}. {summary}")

    lines.extend(["", "## Recurring Feedback Categories"])
    if category_counts:
        for category, count in category_counts.most_common():
            lines.append(f"- `{category}`: {count}")
    else:
        lines.append("- No structured feedback categories yet.")

    lines.extend(["", "## Most Requested Changes"])
    if desired_change_counts:
        for desired_change, count in desired_change_counts.most_common(5):
            lines.append(f"- {count}x: {desired_change}")
    else:
        lines.append("- No requested changes yet.")

    lines.extend(["", "## Recommended Skill Enhancements"])
    if category_counts:
        used_recommendations = set()
        for category, _ in category_counts.most_common():
            recommendation = CATEGORY_RECOMMENDATIONS.get(
                category,
                "Review the repeated feedback and add clearer guidance, examples, or checks to the skill.",
            )
            if recommendation in used_recommendations:
                continue
            used_recommendations.add(recommendation)
            lines.append(f"- {recommendation}")
    else:
        lines.append("- Add human feedback to at least one case to generate skill enhancement guidance.")

    summary_path = run_dir / "summary.md"
    write_text(summary_path, "\n".join(lines) + "\n")
    return summary_path


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run a prompt/output/feedback loop for Codex skills.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    init_parser = subparsers.add_parser("init", help="Create a new skill evaluation run.")
    init_parser.add_argument("--config", required=True, type=Path, help="Path to the JSON config file.")
    init_parser.add_argument("--run-name", help="Optional stable run name.")

    advance_parser = subparsers.add_parser("advance", help="Create the next iteration for reviewed cases.")
    advance_parser.add_argument("--run-dir", required=True, type=Path, help="Existing run directory.")

    summarize_parser = subparsers.add_parser("summarize", help="Refresh the summary file for a run.")
    summarize_parser.add_argument("--run-dir", required=True, type=Path, help="Existing run directory.")

    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])

    if args.command == "init":
        run_dir = init_run(args.config, args.run_name)
        print(run_dir)
        return 0

    if args.command == "advance":
        created = advance_run(args.run_dir)
        for path in created:
            print(path)
        return 0

    if args.command == "summarize":
        summary_path = summarize_run(args.run_dir)
        print(summary_path)
        return 0

    raise ValueError(f"Unsupported command: {args.command}")


if __name__ == "__main__":
    raise SystemExit(main())
