from django.urls import path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from .views import RegisterView, MeView, AuthoritiesView, AdminUsersView, LogoutView

urlpatterns = [
    path('register/', RegisterView.as_view()),
    path('login/', TokenObtainPairView.as_view()),
    path('token/refresh/', TokenRefreshView.as_view()),
    path('me/', MeView.as_view()),
    path('authorities/', AuthoritiesView.as_view()),
    path('admin/users/', AdminUsersView.as_view()),
    path('logout/', LogoutView.as_view()),
]
