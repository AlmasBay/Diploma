 package com.example.newsapp.controller;

import com.example.newsapp.entity.NewsPortal;
import com.example.newsapp.repository.NewsPortalRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/news")
@RequiredArgsConstructor
public class NewsController {

    private final NewsPortalRepository newsRepo;

    // Получить все новости
    @GetMapping("/all")
    public List<NewsPortal> getAll() {
        return newsRepo.findAll();
    }

    // Добавить новость (ADMIN)
    @PostMapping("/add")
    public ResponseEntity<NewsPortal> addNews(@RequestBody NewsPortal news) {
        return ResponseEntity.ok(newsRepo.save(news));
    }

    // Обновить новость (ADMIN)
    @PutMapping("/{id}")
    public ResponseEntity<?> updateNews(@PathVariable Long id, @RequestBody NewsPortal updatedNews) {
        Optional<NewsPortal> optionalNews = newsRepo.findById(id);
        if (optionalNews.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        NewsPortal news = optionalNews.get();
        news.setTitle(updatedNews.getTitle());
        news.setUrl(updatedNews.getUrl());
        news.setDescription(updatedNews.getDescription());
        news.setCategory(updatedNews.getCategory());

        return ResponseEntity.ok(newsRepo.save(news));
    }

    // Удалить новость (ADMIN)
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteNews(@PathVariable Long id) {
        if (!newsRepo.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        newsRepo.deleteById(id);
        return ResponseEntity.ok("Новость успешно удалена");
    }
}
