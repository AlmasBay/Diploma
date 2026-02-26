package com.example.newsapp.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "news_portals")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class NewsPortal {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;
    private String url;
    private String description;

    @ManyToOne
    @JoinColumn(name = "category_id")
    private Category category;
}
