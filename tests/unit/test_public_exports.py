from __future__ import annotations

import csv
import json
from datetime import UTC, datetime, timedelta
from pathlib import Path

from opportunities.models.enums import EmploymentType, JobStatus, OpportunityCategory
from opportunities.models.job import StoredJob
from opportunities.public_exports import (
    CSV_FILENAME,
    JSON_FILENAME,
    PUBLIC_EXPORT_FIELDS,
    render_public_exports,
    validate_public_exports,
)


def stored_job(index: int, first_seen_at: datetime) -> StoredJob:
    return StoredJob(
        linkedin_job_id=str(1_000_000_000 + index),
        company=f"Company {index}",
        title=f"Software Engineer 2027 #{index}",
        location="Zürich, Switzerland",
        link=f"https://www.linkedin.com/jobs/view/{1_000_000_000 + index}",
        category=OpportunityCategory.SOFTWARE_ENGINEERING,
        industries="Software Development",
        employment_type=EmploymentType.INTERNSHIP,
        start_date="Summer 2027",
        first_seen_at=first_seen_at,
        last_seen_at=first_seen_at,
        updated_at=first_seen_at,
        status=JobStatus.OPEN,
    )


def test_public_exports_include_only_approved_fields_in_stable_order(tmp_path: Path) -> None:
    now = datetime(2026, 7, 15, tzinfo=UTC)
    jobs = [
        stored_job(1, now),
        stored_job(2, now + timedelta(minutes=1)),
        stored_job(3, now + timedelta(minutes=2)).model_copy(update={"status": JobStatus.CLOSED}),
    ]

    assert validate_public_exports(tmp_path, jobs) == [
        f"public export is missing: {CSV_FILENAME}",
        f"public export is missing: {JSON_FILENAME}",
    ]

    render_public_exports(tmp_path, jobs)

    json_rows = json.loads((tmp_path / JSON_FILENAME).read_text(encoding="utf-8"))
    assert [row["linkedin_job_id"] for row in json_rows] == ["1000000002", "1000000001"]
    assert tuple(json_rows[0]) == PUBLIC_EXPORT_FIELDS
    assert "first_seen_at" not in json_rows[0]
    assert "status" not in json_rows[0]
    assert "Zürich" in json_rows[0]["location"]

    with (tmp_path / CSV_FILENAME).open(encoding="utf-8", newline="") as handle:
        csv_rows = list(csv.DictReader(handle))
    assert tuple(csv_rows[0]) == PUBLIC_EXPORT_FIELDS
    assert [row["linkedin_job_id"] for row in csv_rows] == ["1000000002", "1000000001"]
    assert validate_public_exports(tmp_path, jobs) == []


def test_public_csv_neutralizes_formulas_and_validation_detects_stale_files(
    tmp_path: Path,
) -> None:
    now = datetime(2026, 7, 15, tzinfo=UTC)
    job = stored_job(1, now).model_copy(update={"company": "=DANGEROUS()"})

    render_public_exports(tmp_path, [job])

    with (tmp_path / CSV_FILENAME).open(encoding="utf-8", newline="") as handle:
        row = next(csv.DictReader(handle))
    assert row["company"] == "'=DANGEROUS()"
    assert json.loads((tmp_path / JSON_FILENAME).read_text(encoding="utf-8"))[0]["company"] == (
        "=DANGEROUS()"
    )

    (tmp_path / JSON_FILENAME).write_text("[]\n", encoding="utf-8")
    assert validate_public_exports(tmp_path, [job]) == [
        f"public export does not match open jobs in SQLite: {JSON_FILENAME}"
    ]
