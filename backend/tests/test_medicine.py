import base64

from unittest.mock import MagicMock, patch

from django.test import TestCase

from rest_framework.test import APIClient

from ai.client import AIInvalidResponse


class MedicineTests(TestCase):
    def setUp(self):
        self.client = APIClient()

        user = type(
            "User",
            (),
            {
                "is_authenticated": True,
                "uid": "test-user",
            },
        )()

        self.client.force_authenticate(
            user=user
        )

        self.record_id = (
            "medicine-record-1"
        )

        self.image_bytes = (
            b"\xff\xd8\xff\xe0"
            + b"\x00" * 100
        )

        self.image_base64 = (
            base64.b64encode(
                self.image_bytes
            ).decode("utf-8")
        )

    def _mock_firestore(
        self,
        *,
        exists=True,
        data=None,
    ):
        db = MagicMock()

        document_ref = MagicMock()

        snapshot = MagicMock()
        snapshot.exists = exists

        if data is None:
            data = {
                "type": "medicine",
                "status": "pending",
                "imageBase64": (
                    self.image_base64
                ),
                "imageMimeType": (
                    "image/jpeg"
                ),
            }

        snapshot.to_dict.return_value = (
            data
        )

        document_ref.get.return_value = (
            snapshot
        )

        (
            db.collection
            .return_value
            .document
            .return_value
            .collection
            .return_value
            .document
            .return_value
        ) = document_ref

        return db, document_ref

    @patch(
        "analyzer.views.validate_upload"
    )
    @patch(
        "analyzer.views.MedicineView.fn"
    )
    @patch(
        "analyzer.views.get_firestore_client"
    )
    def test_medicine_analysis_success(
        self,
        mock_firestore_client,
        mock_analyze,
        mock_validate_upload,
    ):
        db, document_ref = (
            self._mock_firestore()
        )

        mock_firestore_client.return_value = (
            db
        )

        mock_analyze.return_value = {
            "type": "medicine",
            "medicine": {
                "name": "Example medicine",
                "generic_name": None,
                "strength": "500 mg",
                "form": "tablet",
            },
            "instructions": {
                "dose": "1 tablet",
                "frequency": (
                    "twice daily"
                ),
                "duration": "5 days",
                "meal_relation": (
                    "after food"
                ),
                "explicit_times": [],
            },
            "suggested_schedule": [
                {
                    "time": "08:00",
                    "label": "Morning",
                    "basis": (
                        "Convenience reminder "
                        "based on printed "
                        "instruction"
                    ),
                },
                {
                    "time": "20:00",
                    "label": "Evening",
                    "basis": (
                        "Convenience reminder "
                        "based on printed "
                        "instruction"
                    ),
                },
            ],
            "schedule_note": (
                "Reminder times are "
                "convenience suggestions."
            ),
            "doctor_name": None,
            "general_information": [],
            "confidence": 0.9,
            "uncertain_fields": [],
            "requires_user_confirmation": True,
        }

        response = self.client.post(
            "/api/v1/analyze/medicine/",
            {
                "record_id": (
                    self.record_id
                ),
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertTrue(
            response.data["success"]
        )

        data = response.data["data"]

        self.assertEqual(
            data["type"],
            "medicine",
        )

        self.assertEqual(
            data["medicine"]["name"],
            "Example medicine",
        )

        self.assertEqual(
            data["instructions"][
                "frequency"
            ],
            "twice daily",
        )

        self.assertEqual(
            len(
                data[
                    "suggested_schedule"
                ]
            ),
            2,
        )

        self.assertTrue(
            data[
                "requires_user_confirmation"
            ]
        )

        mock_validate_upload.assert_called_once()

        mock_analyze.assert_called_once()

        self.assertGreaterEqual(
            document_ref.update.call_count,
            2,
        )

    @patch(
        "analyzer.views.validate_upload"
    )
    @patch(
        "analyzer.views.MedicineView.fn"
    )
    @patch(
        "analyzer.views.get_firestore_client"
    )
    def test_uncertain_missing_dose(
        self,
        mock_firestore_client,
        mock_analyze,
        mock_validate_upload,
    ):
        db, _ = self._mock_firestore()

        mock_firestore_client.return_value = (
            db
        )

        mock_analyze.return_value = {
            "type": "medicine",
            "medicine": {
                "name": "Example medicine",
                "generic_name": None,
                "strength": None,
                "form": "tablet",
            },
            "instructions": {
                "dose": None,
                "frequency": (
                    "twice daily"
                ),
                "duration": None,
                "meal_relation": None,
                "explicit_times": [],
            },
            "suggested_schedule": [],
            "schedule_note": None,
            "doctor_name": None,
            "general_information": [],
            "confidence": 0.8,
            "uncertain_fields": [
                "instructions.dose"
            ],
            "requires_user_confirmation": True,
        }

        response = self.client.post(
            "/api/v1/analyze/medicine/",
            {
                "record_id": (
                    self.record_id
                ),
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            200,
        )

        self.assertIsNone(
            response.data[
                "data"
            ][
                "instructions"
            ][
                "dose"
            ]
        )

        self.assertIn(
            "instructions.dose",
            response.data[
                "data"
            ][
                "uncertain_fields"
            ],
        )

    @patch(
        "analyzer.views.get_firestore_client"
    )
    def test_scan_not_found(
        self,
        mock_firestore_client,
    ):
        db, _ = self._mock_firestore(
            exists=False
        )

        mock_firestore_client.return_value = (
            db
        )

        response = self.client.post(
            "/api/v1/analyze/medicine/",
            {
                "record_id": (
                    self.record_id
                ),
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            404,
        )

        self.assertEqual(
            response.data["error"]["code"],
            "SCAN_NOT_FOUND",
        )

    @patch(
        "analyzer.views.get_firestore_client"
    )
    def test_wrong_scan_type(
        self,
        mock_firestore_client,
    ):
        db, _ = self._mock_firestore(
            data={
                "type": "meal",
                "status": "pending",
                "imageBase64": (
                    self.image_base64
                ),
                "imageMimeType": (
                    "image/jpeg"
                ),
            }
        )

        mock_firestore_client.return_value = (
            db
        )

        response = self.client.post(
            "/api/v1/analyze/medicine/",
            {
                "record_id": (
                    self.record_id
                ),
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            400,
        )

        self.assertEqual(
            response.data["error"]["code"],
            "INVALID_SCAN_TYPE",
        )

    @patch(
        "analyzer.views.get_firestore_client"
    )
    def test_missing_image(
        self,
        mock_firestore_client,
    ):
        db, _ = self._mock_firestore(
            data={
                "type": "medicine",
                "status": "pending",
                "imageMimeType": (
                    "image/jpeg"
                ),
            }
        )

        mock_firestore_client.return_value = (
            db
        )

        response = self.client.post(
            "/api/v1/analyze/medicine/",
            {
                "record_id": (
                    self.record_id
                ),
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            400,
        )

        self.assertEqual(
            response.data["error"]["code"],
            "IMAGE_NOT_FOUND",
        )

    @patch(
        "analyzer.views.get_firestore_client"
    )
    def test_invalid_base64(
        self,
        mock_firestore_client,
    ):
        db, _ = self._mock_firestore(
            data={
                "type": "medicine",
                "status": "pending",
                "imageBase64": (
                    "not-valid-base64@@@"
                ),
                "imageMimeType": (
                    "image/jpeg"
                ),
            }
        )

        mock_firestore_client.return_value = (
            db
        )

        response = self.client.post(
            "/api/v1/analyze/medicine/",
            {
                "record_id": (
                    self.record_id
                ),
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            400,
        )

        self.assertEqual(
            response.data["error"]["code"],
            "INVALID_IMAGE_DATA",
        )

    @patch(
        "analyzer.views.get_firestore_client"
    )
    def test_unsupported_mime_type(
        self,
        mock_firestore_client,
    ):
        db, _ = self._mock_firestore(
            data={
                "type": "medicine",
                "status": "pending",
                "imageBase64": (
                    self.image_base64
                ),
                "imageMimeType": (
                    "image/gif"
                ),
            }
        )

        mock_firestore_client.return_value = (
            db
        )

        response = self.client.post(
            "/api/v1/analyze/medicine/",
            {
                "record_id": (
                    self.record_id
                ),
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            400,
        )

        self.assertEqual(
            response.data["error"]["code"],
            "UNSUPPORTED_IMAGE_TYPE",
        )

    @patch(
        "analyzer.views.validate_upload"
    )
    @patch(
        "analyzer.views.MedicineView.fn",
        side_effect=AIInvalidResponse(
            "Invalid AI response"
        ),
    )
    @patch(
        "analyzer.views.get_firestore_client"
    )
    def test_ai_invalid_response(
        self,
        mock_firestore_client,
        mock_analyze,
        mock_validate_upload,
    ):
        db, document_ref = (
            self._mock_firestore()
        )

        mock_firestore_client.return_value = (
            db
        )

        response = self.client.post(
            "/api/v1/analyze/medicine/",
            {
                "record_id": (
                    self.record_id
                ),
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            502,
        )

        self.assertEqual(
            response.data["error"]["code"],
            "AI_INVALID_RESPONSE",
        )

        self.assertTrue(
            document_ref.update.called
        )

    def test_record_id_required(self):
        response = self.client.post(
            "/api/v1/analyze/medicine/",
            {},
            format="json",
        )

        self.assertEqual(
            response.status_code,
            400,
        )

    def test_record_id_rejects_path(
        self,
    ):
        response = self.client.post(
            "/api/v1/analyze/medicine/",
            {
                "record_id": (
                    "abc/def"
                ),
            },
            format="json",
        )

        self.assertEqual(
            response.status_code,
            400,
        )
