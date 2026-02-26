package com.example.newsapp.controller;

import com.example.newsapp.entity.NewsPortal;
import com.example.newsapp.entity.Category;
import com.example.newsapp.repository.NewsPortalRepository;
import com.example.newsapp.repository.CategoryRepository;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api/news-portal")
@CrossOrigin(origins = "*")
public class NewsPortalController {

    private final NewsPortalRepository newsRepo;
    private final CategoryRepository categoryRepo;

    public NewsPortalController(NewsPortalRepository newsRepo, CategoryRepository categoryRepo) {
        this.newsRepo = newsRepo;
        this.categoryRepo = categoryRepo;
    }

    @GetMapping("/all")
    public List<NewsPortal> getAll() {
        return newsRepo.findAll();
    }

    @PostMapping("/add")
    public NewsPortal addPortal(@RequestBody NewsPortal portal) {
        if (portal.getCategory() != null && portal.getCategory().getId() != null) {
            Category cat = categoryRepo.findById(portal.getCategory().getId())
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Category not found"));
            portal.setCategory(cat);
        }
        return newsRepo.save(portal);
    }

    @PutMapping("/{id}")
    public NewsPortal updatePortal(@PathVariable Long id, @RequestBody NewsPortal updatedPortal) {
        NewsPortal existing = newsRepo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "News not found"));

        existing.setTitle(updatedPortal.getTitle());
        existing.setUrl(updatedPortal.getUrl());
        existing.setDescription(updatedPortal.getDescription());

        if (updatedPortal.getCategory() != null && updatedPortal.getCategory().getId() != null) {
            Category cat = categoryRepo.findById(updatedPortal.getCategory().getId())
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Category not found"));
            existing.setCategory(cat);
        } else {
            existing.setCategory(null);
        }

        return newsRepo.save(existing);
    }

    @DeleteMapping("/{id}")
    public void deletePortal(@PathVariable Long id) {
        if (!newsRepo.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "News not found");
        }
        newsRepo.deleteById(id);
    }

    // 🔍    Серверный поиск
    @GetMapping("/search")
    public List<NewsPortal> search(@RequestParam String q) {
        if (q == null || q.trim().isEmpty()) {
            return newsRepo.findAll();
        }
        return newsRepo.search(q.trim());
    }
}
