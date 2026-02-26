package com.example.newsapp.service;

import com.example.newsapp.entity.PasswordResetToken;
import com.example.newsapp.entity.User;
import com.example.newsapp.repository.PasswordResetTokenRepository;
import com.example.newsapp.repository.UserRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.Locale;

@Service
@RequiredArgsConstructor
@Slf4j
public class PasswordResetService {

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();
    private static final int RAW_TOKEN_BYTES = 32;
    private static final int MIN_PASSWORD_LENGTH = 6;

    private final UserRepository userRepository;
    private final PasswordResetTokenRepository passwordResetTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final ObjectProvider<JavaMailSender> mailSenderProvider;

    @Value("${app.password-reset.token-expiration-minutes:30}")
    private long tokenExpirationMinutes;

    @Value("${app.password-reset.frontend-url-template:http://localhost:3000/reset-password?token={token}}")
    private String resetUrlTemplate;

    @Value("${app.password-reset.mail-from:no-reply@infohub.local}")
    private String mailFrom;

    @Value("${app.password-reset.mail-subject:Password reset}")
    private String mailSubject;

    @Value("${app.password-reset.mail-enabled:false}")
    private boolean mailEnabled;

    @Transactional
    public void requestPasswordReset(String emailRaw, String requestIp, String userAgent) {
        if (emailRaw == null || emailRaw.isBlank()) {
            return;
        }

        String email = emailRaw.trim().toLowerCase(Locale.ROOT);
        var userOptional = userRepository.findByEmailIgnoreCase(email);
        if (userOptional.isEmpty()) {
            log.info("Password reset requested for unknown email: {}", email);
            return;
        }

        User user = userOptional.get();
        LocalDateTime now = LocalDateTime.now();
        passwordResetTokenRepository.invalidateAllActiveForUser(user.getId(), now);

        String rawToken = generateRawToken();
        PasswordResetToken token = new PasswordResetToken();
        token.setUser(user);
        token.setTokenHash(hashToken(rawToken));
        token.setCreatedAt(now);
        token.setExpiresAt(now.plusMinutes(Math.max(tokenExpirationMinutes, 1)));
        token.setRequestIp(trimToLength(requestIp, 64));
        token.setUserAgent(trimToLength(userAgent, 255));
        passwordResetTokenRepository.save(token);

        String resetUrl = buildResetUrl(rawToken);
        sendResetEmail(user.getEmail(), user.getDisplayName(), resetUrl);
    }

    @Transactional
    public void resetPassword(String rawToken, String newPassword) {
        String token = normalizeToken(rawToken);
        String normalizedPassword = normalizePassword(newPassword);

        PasswordResetToken storedToken = passwordResetTokenRepository.findByTokenHash(hashToken(token))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid or expired reset token"));

        LocalDateTime now = LocalDateTime.now();
        if (storedToken.getUsedAt() != null || storedToken.getExpiresAt().isBefore(now)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid or expired reset token");
        }

        User user = storedToken.getUser();
        user.setPassword(passwordEncoder.encode(normalizedPassword));
        userRepository.save(user);

        storedToken.setUsedAt(now);
        passwordResetTokenRepository.save(storedToken);
        passwordResetTokenRepository.invalidateAllActiveForUser(user.getId(), now);
    }

    private String normalizeToken(String rawToken) {
        if (rawToken == null || rawToken.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Reset token is required");
        }
        return rawToken.trim();
    }

    private String normalizePassword(String newPassword) {
        if (newPassword == null || newPassword.length() < MIN_PASSWORD_LENGTH) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Password must be at least " + MIN_PASSWORD_LENGTH + " characters"
            );
        }
        return newPassword;
    }

    private String generateRawToken() {
        byte[] bytes = new byte[RAW_TOKEN_BYTES];
        SECURE_RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private String hashToken(String rawToken) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(rawToken.getBytes(StandardCharsets.UTF_8));
            return bytesToHex(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 is not available", e);
        }
    }

    private String bytesToHex(byte[] bytes) {
        StringBuilder builder = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) {
            builder.append(String.format("%02x", b));
        }
        return builder.toString();
    }

    private String buildResetUrl(String rawToken) {
        if (resetUrlTemplate == null || resetUrlTemplate.isBlank()) {
            return "http://localhost:3000/reset-password?token=" + rawToken;
        }

        if (resetUrlTemplate.contains("{token}")) {
            return resetUrlTemplate.replace("{token}", rawToken);
        }

        String separator = resetUrlTemplate.contains("?") ? "&" : "?";
        return resetUrlTemplate + separator + "token=" + rawToken;
    }

    private void sendResetEmail(String email, String displayName, String resetUrl) {
        if (!mailEnabled) {
            log.info("Password reset link for {}: {}", email, resetUrl);
            return;
        }

        JavaMailSender mailSender = mailSenderProvider.getIfAvailable();
        if (mailSender == null) {
            log.warn("Mail sender is not configured. Reset link for {}: {}", email, resetUrl);
            return;
        }

        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(email);
        message.setFrom(mailFrom);
        message.setSubject(mailSubject);
        message.setText(buildEmailBody(displayName, resetUrl));

        try {
            mailSender.send(message);
            log.info("Password reset email sent to {}", email);
        } catch (Exception e) {
            log.error("Failed to send password reset email to {}: {}", email, e.getMessage());
        }
    }

    private String buildEmailBody(String displayName, String resetUrl) {
        String safeDisplayName = (displayName == null || displayName.isBlank()) ? "user" : displayName;
        return "Hello, " + safeDisplayName + "!\n\n"
                + "We received a request to reset your password.\n"
                + "Open this link to set a new password:\n"
                + resetUrl + "\n\n"
                + "This link will expire in " + Math.max(tokenExpirationMinutes, 1) + " minutes.\n"
                + "If you did not request a password reset, you can ignore this email.";
    }

    private String trimToLength(String value, int maxLength) {
        if (value == null) return null;
        String trimmed = value.trim();
        if (trimmed.length() <= maxLength) return trimmed;
        return trimmed.substring(0, maxLength);
    }
}
