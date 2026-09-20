from rest_framework import serializers


class AnalyzeSavedImageSerializer(
    serializers.Serializer,
):
    record_id = serializers.CharField(
        required=True,
        allow_blank=False,
        trim_whitespace=True,
        max_length=200,
    )

    def validate_record_id(
        self,
        value,
    ):
        value = value.strip()

        if "/" in value:
            raise serializers.ValidationError(
                "Invalid record_id."
            )

        return value


class AnalyzeReportSerializer(
    serializers.Serializer,
):
    record_id = serializers.CharField(
        required=False,
        allow_blank=False,
        trim_whitespace=True,
        max_length=200,
    )

    file = serializers.FileField(
        required=False,
    )

    def validate_record_id(
        self,
        value,
    ):
        value = value.strip()

        if "/" in value:
            raise serializers.ValidationError(
                "Invalid record_id."
            )

        return value

    def validate(
        self,
        attrs,
    ):
        record_id = attrs.get(
            "record_id"
        )

        upload = attrs.get(
            "file"
        )

        if not record_id and not upload:
            raise serializers.ValidationError(
                "Provide either record_id or file."
            )

        if record_id and upload:
            raise serializers.ValidationError(
                "Provide only one of record_id or file."
            )

        return attrs