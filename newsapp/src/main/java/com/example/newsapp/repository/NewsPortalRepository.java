package com.example.newsapp.repository;

import com.example.newsapp.entity.NewsPortal;
import com.example.newsapp.entity.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface NewsPortalRepository extends JpaRepository<NewsPortal, Long> {

    List<NewsPortal> findByCategory(Category category);

    // 🔍 Поиск по новостям + категории
    @Query("""
        SELECT n FROM NewsPortal n
        LEFT JOIN n.category c
        WHERE LOWER(n.title) LIKE LOWER(CONCAT('%', :q, '%'))
           OR LOWER(n.description) LIKE LOWER(CONCAT('%', :q, '%'))
           OR LOWER(n.url) LIKE LOWER(CONCAT('%', :q, '%'))
           OR LOWER(c.name) LIKE LOWER(CONCAT('%', :q, '%'))
    """)
    List<NewsPortal> search(@Param("q") String q);
}
