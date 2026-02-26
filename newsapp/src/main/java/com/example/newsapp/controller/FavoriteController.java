package com.example.newsapp.controller;

import com.example.newsapp.entity.Favorite;
import com.example.newsapp.service.FavoriteService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/favorites")
@CrossOrigin(origins = "*")
public class FavoriteController {

    private final FavoriteService favoriteService;

    public FavoriteController(FavoriteService favoriteService) {
        this.favoriteService = favoriteService;
    }

    // Получение всех избранных новостей пользователя
    @GetMapping("/{userId}")
    public ResponseEntity<List<Favorite>> getFavorites(@PathVariable Long userId) {
        List<Favorite> favorites = favoriteService.getFavorites(userId);
        return ResponseEntity.ok(favorites);
    }

    // Добавление / удаление из избранного
    @PostMapping("/{userId}/{newsId}")
    public ResponseEntity<String> toggleFavorite(@PathVariable Long userId, @PathVariable Long newsId) {
        boolean added = favoriteService.toggleFavorite(userId, newsId);
        return ResponseEntity.ok(added ? "added" : "removed");
    }
}
