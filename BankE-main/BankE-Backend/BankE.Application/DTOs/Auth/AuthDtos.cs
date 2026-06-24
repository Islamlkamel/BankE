namespace BankE.Application.DTOs
{
    public record RegisterRequest(string FullName, string Email, string PhoneNumber, string Password);
    public record LoginRequest(string Email, string Password);
    public record VerifyOtpRequest(string Email, string OtpCode);
    public record AuthResponse(string Token, string Message);
    public record RefreshTokenRequest(string RefreshToken);
    public record ForgotPasswordRequest(string Email);
    public record ResetPasswordRequest(string Email, string OtpCode, string NewPassword);
}
