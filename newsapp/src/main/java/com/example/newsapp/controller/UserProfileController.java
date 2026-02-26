package com.example.newsapp.controller;

import com.example.newsapp.entity.User;
import com.example.newsapp.repository.UserRepository;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.Set;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class UserProfileController {

    private static final Set<String> ALLOWED_THEMES = Set.of("SYSTEM", "LIGHT", "DARK");
    private static final int MAX_AVATAR_BASE64_LENGTH = 2_000_000;

    private final UserRepository userRepository;

    @GetMapping("/me")
    public UserProfileResponse getCurrentUserProfile(Authentication authentication) {
        User user = resolveCurrentUser(authentication);
        return UserProfileResponse.fromUser(user);
    }

    @PutMapping("/me")
    public UserProfileResponse updateCurrentUserProfile(
            Authentication authentication,
            @RequestBody UpdateProfileRequest request
    ) {
        User user = resolveCurrentUser(authentication);

        String username = normalizeUsername(request.getUsername());
        String themePreference = normalizeThemePreference(request.getThemePreference());
        String avatarBase64 = normalizeAvatar(request.getAvatarBase64());

        user.setUsername(username);
        user.setThemePreference(themePreference);
        user.setAvatarBase64(avatarBase64);

        User saved = userRepository.save(user);
        return UserProfileResponse.fromUser(saved);
    }

    private User resolveCurrentUser(Authentication authentication) {
        if (authentication == null || authentication.getName() == null || authentication.getName().isBlank()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Unauthorized");
        }

        return userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
    }

    private String normalizeUsername(String username) {
        if (username == null || username.trim().length() < 3) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Username must be at least 3 characters");
        }
        return username.trim();
    }

    private String normalizeThemePreference(String themePreference) {
        if (themePreference == null || themePreference.isBlank()) {
            return "SYSTEM";
        }

        String normalized = themePreference.trim().toUpperCase();
        if (!ALLOWED_THEMES.contains(normalized)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Unsupported theme value");
        }
        return normalized;
    }

    private String normalizeAvatar(String avatarBase64) {
        if (avatarBase64 == null) return null;

        String normalized = avatarBase64.trim();
        if (normalized.isEmpty()) return null;

        if (normalized.startsWith("data:")) {
            int commaIndex = normalized.indexOf(',');
            if (commaIndex > 0 && commaIndex + 1 < normalized.length()) {
                normalized = normalized.substring(commaIndex + 1);
            }
        }

        if (normalized.length() > MAX_AVATAR_BASE64_LENGTH) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Avatar is too large");
        }

        return normalized;
    }

    @Data
    public static class UpdateProfileRequest {
        private String username;
        private String avatarBase64;
        private String themePreference;
    }

    @Data
    public static class UserProfileResponse {
        private Long id;
        private String email;
        private String username;
        private String role;
        private String avatarBase64;
        private String themePreference;

        public static UserProfileResponse fromUser(User user) {
            UserProfileResponse response = new UserProfileResponse();
            response.setId(user.getId());
            response.setEmail(user.getEmail());
            response.setUsername(user.getDisplayName());
            response.setRole(user.getRole());
            response.setAvatarBase64(user.getAvatarBase64());
            response.setThemePreference(user.getThemePreference() == null ? "SYSTEM" : user.getThemePreference());
            return response;
        }
    }
}
