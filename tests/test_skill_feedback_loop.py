import json
import tempfile
import unittest
from pathlib import Path

from tools.skill_feedback_loop import advance_run, init_run, summarize_run


class SkillFeedbackLoopTests(unittest.TestCase):
    def write_config(self, root: Path) -> Path:
        config = {
            "name": "test-loop",
            "skill_name": "rich-office-documents",
            "skill_path": "rich-office-documents/SKILL.md",
            "run_root": str(root / "outputs"),
            "max_iterations": 3,
            "cases": [
                {
                    "id": "bundle-case",
                    "prompt": "Use $rich-office-documents to create a board-ready deck and PDF.",
                    "success_criteria": ["Creates a deck.", "Creates a PDF."],
                }
            ],
        }
        config_path = root / "config.json"
        config_path.write_text(json.dumps(config), encoding="utf-8")
        return config_path

    def test_init_creates_first_iteration_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            run_dir = init_run(self.write_config(root), run_name="stable-run")

            iteration_dir = run_dir / "cases" / "bundle-case" / "iteration-01"
            self.assertTrue((iteration_dir / "prompt.txt").exists())
            self.assertTrue((iteration_dir / "output.md").exists())
            self.assertTrue((iteration_dir / "feedback.template.json").exists())

            prompt = (iteration_dir / "prompt.txt").read_text(encoding="utf-8")
            self.assertIn("Use $rich-office-documents", prompt)
            self.assertIn("Creates a deck.", prompt)

    def test_advance_uses_feedback_to_create_next_iteration(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            run_dir = init_run(self.write_config(root), run_name="stable-run")
            first_iteration = run_dir / "cases" / "bundle-case" / "iteration-01"

            (first_iteration / "output.md").write_text(
                "Initial output used a plain layout and skipped the PDF export.",
                encoding="utf-8",
            )
            feedback = {
                "approved": False,
                "score": 1,
                "summary": "Output was too plain and incomplete.",
                "items": [
                    {
                        "severity": "high",
                        "category": "quality",
                        "issue": "The design was generic.",
                        "desired_change": "Use a stronger visual system.",
                    }
                ],
            }
            (first_iteration / "feedback.json").write_text(json.dumps(feedback), encoding="utf-8")

            created = advance_run(run_dir)

            self.assertEqual(len(created), 1)
            second_iteration = run_dir / "cases" / "bundle-case" / "iteration-02"
            prompt = (second_iteration / "prompt.txt").read_text(encoding="utf-8")
            self.assertIn("Initial output used a plain layout", prompt)
            self.assertIn("Use a stronger visual system.", prompt)

    def test_summary_includes_recommendations(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            run_dir = init_run(self.write_config(root), run_name="stable-run")
            first_iteration = run_dir / "cases" / "bundle-case" / "iteration-01"
            feedback = {
                "approved": False,
                "score": 1,
                "summary": "Workflow was unclear and output formatting was weak.",
                "items": [
                    {
                        "severity": "high",
                        "category": "workflow",
                        "issue": "The routing order was vague.",
                        "desired_change": "Clarify the sequence of steps.",
                    },
                    {
                        "severity": "medium",
                        "category": "format",
                        "issue": "The output structure was inconsistent.",
                        "desired_change": "Add a fixed structure for design brief and deliverables.",
                    },
                ],
            }
            (first_iteration / "feedback.json").write_text(json.dumps(feedback), encoding="utf-8")

            summary_path = summarize_run(run_dir)
            summary = summary_path.read_text(encoding="utf-8")

            self.assertIn("workflow", summary)
            self.assertIn("format", summary)
            self.assertIn("Clarify the order of operations", summary)


if __name__ == "__main__":
    unittest.main()
