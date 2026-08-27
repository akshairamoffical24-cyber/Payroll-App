package com.freelance.payroll.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.ResultSet;
import java.sql.Statement;

@Slf4j
@Component
@Order(1)
@RequiredArgsConstructor
public class DatabaseHealthCheck implements CommandLineRunner {

    private final DataSource dataSource;

    @Override
    public void run(String... args) {
        log.info("============================================================");
        log.info("Checking PostgreSQL Database Connection & JPA State...");
        log.info("============================================================");

        try (Connection conn = dataSource.getConnection()) {
            DatabaseMetaData metaData = conn.getMetaData();
            log.info("✓ PostgreSQL Connection Successful!");
            log.info("• Database Product Name : {}", metaData.getDatabaseProductName());
            log.info("• Database Version      : {}", metaData.getDatabaseProductVersion());
            log.info("• Driver Name & Version : {} ({})", metaData.getDriverName(), metaData.getDriverVersion());
            log.info("• JDBC Connection URL   : {}", metaData.getURL());
            log.info("• Connected User        : {}", metaData.getUserName());

            if (metaData.getDatabaseProductName().toLowerCase().contains("postgres")) {
                try (Statement stmt = conn.createStatement();
                     ResultSet rs = stmt.executeQuery("SELECT current_database(), current_schema()")) {
                    if (rs.next()) {
                        log.info("• Active Database       : {}", rs.getString(1));
                        log.info("• Active Schema         : {}", rs.getString(2));
                    }
                }
            } else {
                log.info("• Catalog / Schema      : {}", conn.getCatalog());
            }
            log.info("============================================================");
        } catch (Exception e) {
            log.error("✗ Failed to connect to PostgreSQL Database: {}", e.getMessage());
            log.error("Please verify that PostgreSQL service is running on localhost:5432 and database 'payroll_attendance' exists.");
            log.error("To create database, run in psql: CREATE DATABASE payroll_attendance;");
            log.info("============================================================");
        }
    }
}
