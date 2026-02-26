package com.example.newsapp.service;

import com.example.newsapp.entity.Favorite;
import com.example.newsapp.entity.NewsPortal;
import com.example.newsapp.entity.User;
import com.example.newsapp.repository.FavoriteRepository;
import com.example.newsapp.repository.NewsPortalRepository;
import com.example.newsapp.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional; // 🔥 добавь это

import java.util.List;

@Service
@RequiredArgsConstructor
public class FavoriteService {

    private final FavoriteRepository favoriteRepository;
    private final UserRepository userRepository;
    private final NewsPortalRepository newsPortalRepository;

    /**
     * Добавляет или удаляет новость из избранного.
     * @return true — если добавлено, false — если удалено.
     */
    @Transactional // ✅ без этого удаление может не срабатывать
    public boolean toggleFavorite(Long userId, Long newsPortalId) {
        boolean exists = favoriteRepository.existsByUserIdAndNewsPortalId(userId, newsPortalId);

        if (exists) {
            favoriteRepository.deleteByUserIdAndNewsPortalId(userId, newsPortalId);
            return false; // ❌ удалено
        } else {
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new RuntimeException("Пользователь не найден"));
            NewsPortal newsPortal = newsPortalRepository.findById(newsPortalId)
                    .orElseThrow(() -> new RuntimeException("Новость не найдена"));

            favoriteRepository.save(new Favorite(null, user, newsPortal));
            return true; // ✅ добавлено
        }
    }

    /**
     * Возвращает все избранные новости пользователя.
     */
    public List<Favorite> getFavorites(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Пользователь не найден"));
        return favoriteRepository.findByUser(user);
    }
}
