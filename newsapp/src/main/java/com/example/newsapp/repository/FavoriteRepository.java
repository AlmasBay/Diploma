package com.example.newsapp.repository;

import com.example.newsapp.entity.Favorite;
import com.example.newsapp.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface FavoriteRepository extends JpaRepository<Favorite, Long> {
    // Получить все избранные новости пользователя
    List<Favorite> findByUser(User user);

    // Проверить, добавлена ли новость в избранное
    boolean existsByUserIdAndNewsPortalId(Long userId, Long newsPortalId);

    // Удалить новость из избранного
    void deleteByUserIdAndNewsPortalId(Long userId, Long newsPortalId);
}
