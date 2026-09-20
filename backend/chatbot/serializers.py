from rest_framework import serializers
import json


class HistoryItemSerializer(serializers.Serializer):
    role = serializers.ChoiceField(
        choices=['user', 'assistant'],
    )
    content = serializers.CharField(
        max_length=2000,
    )


class ChatSerializer(serializers.Serializer):
    message = serializers.CharField(
        max_length=4000,
    )

    history = HistoryItemSerializer(
        many=True,
        required=False,
        default=list,
    )

    context = serializers.JSONField(
        required=False,
        default=dict,
    )

    def validate_history(self, value):
        if len(value) > 12:
            raise serializers.ValidationError(
                'Maximum 12 history messages.'
            )

        return value

    def validate_context(self, value):
        size = len(
            json.dumps(
                value,
                ensure_ascii=False,
            ).encode()
        )

        if size > 20_000:
            raise serializers.ValidationError(
                'Context is too large.'
            )

        return value