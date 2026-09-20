MEAL_SCHEMA={'type':'OBJECT','properties':{'type':{'type':'STRING'},'foods':{'type':'ARRAY','items':{'type':'OBJECT','properties':{'name':{'type':'STRING'},'estimated_portion':{'type':'STRING','nullable':True},'estimated_grams':{'type':'NUMBER','nullable':True},'confidence':{'type':'NUMBER'}},'required':['name','confidence']}},'nutrition':{'type':'OBJECT','properties':{'estimated_calories_kcal':{'type':'NUMBER','nullable':True},'estimated_protein_g':{'type':'NUMBER','nullable':True},'estimated_carbs_g':{'type':'NUMBER','nullable':True},'estimated_fat_g':{'type':'NUMBER','nullable':True}}},'is_estimate':{'type':'BOOLEAN'},'notes':{'type':'ARRAY','items':{'type':'STRING'}}},'required':['type','foods','nutrition','is_estimate','notes']}
MEDICINE_SCHEMA = {
    "type": "OBJECT",
    "properties": {
        "type": {
            "type": "STRING",
        },

        "medicine": {
            "type": "OBJECT",
            "properties": {
                "name": {
                    "type": "STRING",
                    "nullable": True,
                },
                "generic_name": {
                    "type": "STRING",
                    "nullable": True,
                },
                "strength": {
                    "type": "STRING",
                    "nullable": True,
                },
                "form": {
                    "type": "STRING",
                    "nullable": True,
                },
            },
            "required": [
                "name",
                "generic_name",
                "strength",
                "form",
            ],
        },

        "instructions": {
            "type": "OBJECT",
            "properties": {
                "dose": {
                    "type": "STRING",
                    "nullable": True,
                },
                "frequency": {
                    "type": "STRING",
                    "nullable": True,
                },
                "duration": {
                    "type": "STRING",
                    "nullable": True,
                },
                "meal_relation": {
                    "type": "STRING",
                    "nullable": True,
                },
                "explicit_times": {
                    "type": "ARRAY",
                    "items": {
                        "type": "STRING",
                    },
                },
            },
            "required": [
                "dose",
                "frequency",
                "duration",
                "meal_relation",
                "explicit_times",
            ],
        },

        "suggested_schedule": {
            "type": "ARRAY",
            "items": {
                "type": "OBJECT",
                "properties": {
                    "time": {
                        "type": "STRING",
                        "nullable": True,
                    },
                    "label": {
                        "type": "STRING",
                        "nullable": True,
                    },
                    "basis": {
                        "type": "STRING",
                        "nullable": True,
                    },
                },
                "required": [
                    "time",
                    "label",
                    "basis",
                ],
            },
        },

        "schedule_note": {
            "type": "STRING",
            "nullable": True,
        },

        "doctor_name": {
            "type": "STRING",
            "nullable": True,
        },

        "general_information": {
            "type": "ARRAY",
            "items": {
                "type": "STRING",
            },
        },

        "confidence": {
            "type": "NUMBER",
        },

        "uncertain_fields": {
            "type": "ARRAY",
            "items": {
                "type": "STRING",
            },
        },

        "requires_user_confirmation": {
            "type": "BOOLEAN",
        },
    },

    "required": [
        "type",
        "medicine",
        "instructions",
        "suggested_schedule",
        "schedule_note",
        "doctor_name",
        "general_information",
        "confidence",
        "uncertain_fields",
        "requires_user_confirmation",
    ],
}
REPORT_SCHEMA = {
    "type": "OBJECT",
    "properties": {
        "type": {
            "type": "STRING",
        },

        "report": {
            "type": "OBJECT",
            "properties": {
                "title": {
                    "type": "STRING",
                    "nullable": True,
                },

                "lab_name": {
                    "type": "STRING",
                    "nullable": True,
                },

                "report_date": {
                    "type": "STRING",
                    "nullable": True,
                },

                "results": {
                    "type": "ARRAY",
                    "items": {
                        "type": "OBJECT",
                        "properties": {
                            "test_name": {
                                "type": "STRING",
                            },
                            "value": {
                                "type": "STRING",
                                "nullable": True,
                            },
                            "unit": {
                                "type": "STRING",
                                "nullable": True,
                            },
                            "reference_range": {
                                "type": "STRING",
                                "nullable": True,
                            },
                            "printed_flag": {
                                "type": "STRING",
                                "nullable": True,
                            },
                        },
                        "required": [
                            "test_name",
                        ],
                    },
                },

                "summary": {
                    "type": "STRING",
                },

                "uncertain_fields": {
                    "type": "ARRAY",
                    "items": {
                        "type": "STRING",
                    },
                },
            },

            "required": [
                "results",
                "summary",
                "uncertain_fields",
            ],
        },

        "doctor_recommendation": {
            "type": "OBJECT",
            "properties": {
                "needed": {
                    "type": "BOOLEAN",
                },
                "speciality": {
                    "type": "STRING",
                    "nullable": True,
                },
                "reason": {
                    "type": "STRING",
                    "nullable": True,
                },
            },
            "required": [
                "needed",
                "speciality",
                "reason",
            ],
        },
    },

    "required": [
        "type",
        "report",
        "doctor_recommendation",
    ],
}
CHAT_SCHEMA = {
    'type': 'OBJECT',
    'properties': {
        'message': {
            'type': 'STRING'
        },
        'doctor_recommendation': {
            'type': 'OBJECT',
            'nullable': True,
            'properties': {
                'needed': {
                    'type': 'BOOLEAN'
                },
                'speciality': {
                    'type': 'STRING',
                    'nullable': True
                },
                'reason': {
                    'type': 'STRING',
                    'nullable': True
                }
            }
        }
    },
    'required': [
        'message',
        'doctor_recommendation'
    ]
}
