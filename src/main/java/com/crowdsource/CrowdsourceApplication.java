package com.crowdsource;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@MapperScan("com.crowdsource.mapper")
public class CrowdsourceApplication {
    public static void main(String[] args) {
        SpringApplication.run(CrowdsourceApplication.class, args);
    }
}
