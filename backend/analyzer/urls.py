from django.urls import path

from .views import (
    HealthView,
    MealView,
    MedicineView,
    ReportView,
)


urlpatterns = [
    path(
        "health/",
        HealthView.as_view(),
        name="health",
    ),

    path(
        "analyze/meal/",
        MealView.as_view(),
        name="analyze-meal",
    ),

    path(
        "analyze/medicine/",
        MedicineView.as_view(),
        name="analyze-medicine",
    ),

    path(
        "analyze/report/",
        ReportView.as_view(),
        name="analyze-report",
    ),
]