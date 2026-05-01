-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: May 01, 2026 at 12:20 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `nyeni_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `events`
--

CREATE TABLE `events` (
  `id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `category` varchar(100) NOT NULL,
  `event_date` varchar(100) NOT NULL,
  `location` varchar(255) NOT NULL,
  `price` int(11) DEFAULT 0,
  `image_url` varchar(500) NOT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `early_bird_deadline` datetime DEFAULT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `events`
--

INSERT INTO `events` (`id`, `title`, `category`, `event_date`, `location`, `price`, `image_url`, `description`, `created_at`, `early_bird_deadline`, `latitude`, `longitude`, `is_active`) VALUES
(1, 'Konser Nyeni Fest 2026', 'Konser', '12 Mei 2026', 'JEC Yogyakarta', 150000, 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?q=80&w=400&auto=format&fit=crop', 'Konser paling nyeni se-Jogja! Bintang tamu rahasia.', '2026-04-29 20:39:25', '2026-05-10 23:59:59', NULL, NULL, 1),
(2, 'Teater Koma: Bunga Penutup', 'Teater', '20 Mei 2026', 'Taman Budaya Yogyakarta', 200000, 'https://images.unsplash.com/photo-1507676184212-d03305a527e4?q=80&w=400&auto=format&fit=crop', 'Pementasan teater koma dengan lakon terbaru.', '2026-04-29 20:39:25', '2026-04-01 23:59:59', NULL, NULL, 1),
(3, 'Pameran Lukis Senja', 'Pameran', '01 Jun 2026', 'Jogja National Museum', 50000, 'https://images.unsplash.com/photo-1460661419201-fd4cecdf8a8b?q=80&w=400&auto=format&fit=crop', 'Pameran instalasi seni dan lukisan dari seniman lokal.', '2026-04-29 20:39:25', NULL, NULL, NULL, 1),
(4, 'Indie Gigs Vol. 4', 'Konser', '15 Jun 2026', 'Liquid Bar Jogja', 75000, 'https://images.unsplash.com/photo-1526478806334-5fd488fcaabc?q=80&w=400&auto=format&fit=crop', 'Gigs intim bareng band indie pujaan kampus.', '2026-04-29 20:39:25', NULL, NULL, NULL, 1),
(5, 'Stand Up Comedy JGJ', 'Stand Up', '22 Jun 2026', 'Auditorium UPN Veteran', 100000, 'https://images.unsplash.com/photo-1585699324551-f6c309eedeca?q=80&w=400&auto=format&fit=crop', 'Ketawa sampe ngompol bareng komika-komika ibukota.', '2026-04-29 20:39:25', NULL, -7.77473700, 110.41445700, 1);

-- --------------------------------------------------------

--
-- Table structure for table `game_scores`
--

CREATE TABLE `game_scores` (
  `id` int(11) NOT NULL,
  `user_id` varchar(50) DEFAULT NULL,
  `username` varchar(100) DEFAULT NULL,
  `game_name` varchar(50) DEFAULT NULL,
  `level` int(11) DEFAULT NULL,
  `best_time` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `game_scores`
--

INSERT INTO `game_scores` (`id`, `user_id`, `username`, `game_name`, `level`, `best_time`, `created_at`) VALUES
(1, '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Atilla Danady', 'Labirin Gyro', 1, 2, '2026-04-30 19:43:53'),
(2, '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Atilla Danady', 'Labirin Gyro', 2, 3, '2026-04-30 19:45:57');

-- --------------------------------------------------------

--
-- Table structure for table `tickets`
--

CREATE TABLE `tickets` (
  `id` varchar(50) NOT NULL,
  `user_id` varchar(50) DEFAULT NULL,
  `event_name` varchar(150) DEFAULT NULL,
  `event_date` varchar(50) DEFAULT NULL,
  `status` varchar(20) DEFAULT 'ACTIVE',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tickets`
--

INSERT INTO `tickets` (`id`, `user_id`, `event_name`, `event_date`, `status`, `created_at`) VALUES
('2972c102-4519-4d80-b165-8c04e7df08fc', '4b64076b-027b-4503-b820-dbb1a5492f5a', 'Indie Music Fest', '10 Juni 2026', 'DECLINED', '2026-04-29 20:21:09'),
('431fe32a-32c5-46bf-a867-09f5271a8422', '4b64076b-027b-4503-b820-dbb1a5492f5a', 'ARTJOG 2026: Motif', '25 Mei - 25 Juli 2026', 'USED', '2026-04-29 20:08:37'),
('453821db-a9fb-4789-a9bf-71de220aef1e', '4b64076b-027b-4503-b820-dbb1a5492f5a', 'Stand Up Comedy JGJ', '22 Jun 2026', '', '2026-04-29 21:15:37'),
('455567fa-8e12-4737-8f51-25526005a4ec', '4b64076b-027b-4503-b820-dbb1a5492f5a', 'ARTJOG 2026: Motif', '25 Mei - 25 Juli 2026', 'PENDING', '2026-04-29 20:01:16'),
('48cf60ea-ec9f-42a1-a107-68373ff09a92', '4b64076b-027b-4503-b820-dbb1a5492f5a', 'ARTJOG 2026: Motif', '25 Mei - 25 Juli 2026', 'PENDING', '2026-04-29 20:11:25'),
('4faf55ac-ba7c-4199-bb30-84b61865a195', '4b64076b-027b-4503-b820-dbb1a5492f5a', 'ARTJOG 2026: Motif', '25 Mei - 25 Juli 2026', 'PENDING', '2026-04-29 20:08:07'),
('57c97156-3a9b-42f1-948d-262fa2bb610a', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Normal', '22 Jun 2026', 'EXPIRED', '2026-04-30 21:52:38'),
('7dbcfa0b-e119-47c1-8909-ad99374e85cf', '4b64076b-027b-4503-b820-dbb1a5492f5a', 'ARTJOG 2026: Motif', '25 Mei - 25 Juli 2026', 'PENDING', '2026-04-29 20:08:29'),
('94ece0be-4dfa-48f9-9f79-eb142c205d0b', '4b64076b-027b-4503-b820-dbb1a5492f5a', 'ARTJOG 2026: Motif', '25 Mei - 25 Juli 2026', 'PENDING', '2026-04-29 20:05:26'),
('d38c73c0-9d3e-4568-b7dd-337eb0b1d8b2', '4b64076b-027b-4503-b820-dbb1a5492f5a', 'Indie Music Fest', '10 Juni 2026', 'PENDING', '2026-04-29 20:12:19'),
('e48bd0c7-6af0-4d82-bb3b-8d81a2d5ff2c', '4b64076b-027b-4503-b820-dbb1a5492f5a', 'ARTJOG 2026: Motif', '25 Mei - 25 Juli 2026', 'PENDING', '2026-04-29 20:11:02'),
('ff8b035a-9df7-4bfb-9189-3569e7efc1f3', '4b64076b-027b-4503-b820-dbb1a5492f5a', 'ARTJOG 2026: Motif', '25 Mei - 25 Juli 2026', 'ACTIVE', '2026-04-29 19:53:16');

-- --------------------------------------------------------

--
-- Table structure for table `tpm_feedbacks`
--

CREATE TABLE `tpm_feedbacks` (
  `id` int(11) NOT NULL,
  `user_id` varchar(50) DEFAULT NULL,
  `username` varchar(100) DEFAULT NULL,
  `feedback` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `rating` decimal(2,1) DEFAULT 5.0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tpm_feedbacks`
--

INSERT INTO `tpm_feedbacks` (`id`, `user_id`, `username`, `feedback`, `created_at`, `rating`) VALUES
(1, '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Atilla Danady', 'halo', '2026-04-30 20:33:24', 5.0),
(2, '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Atilla Danady', 'mntap aku suka tpm', '2026-04-30 20:33:34', 5.0),
(3, '4b64076b-027b-4503-b820-dbb1a5492f5a', 'atta', 'jelek', '2026-04-30 20:33:59', 5.0),
(4, '4b64076b-027b-4503-b820-dbb1a5492f5a', 'atta', 'jos', '2026-04-30 20:39:28', 4.0),
(5, '4b64076b-027b-4503-b820-dbb1a5492f5a', 'atta', 'yes', '2026-04-30 20:39:38', 3.5);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `total_xp` int(11) DEFAULT 0,
  `level` int(11) DEFAULT 1,
  `completed_levels_trivia` int(11) DEFAULT 1,
  `completed_levels_labirin` int(11) DEFAULT 1,
  `avatar_url` text DEFAULT NULL,
  `role` varchar(20) NOT NULL DEFAULT 'user'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `email`, `password`, `full_name`, `total_xp`, `level`, `completed_levels_trivia`, `completed_levels_labirin`, `avatar_url`, `role`) VALUES
('1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'aksa@gmail.com', '$2b$10$TsSQx2GYX5Jn1zxvdST4uOqqDNPrhbLmvYiWKwbZGVU.aODnTEr.a', 'Atilla Danady', 400, 3, 3, 3, 'http://localhost:3000/uploads/avatar-1777580784385.jpg', 'user'),
('2fc6d0e8-44db-11f1-8a7c-0a0027000005', 'admin@nyeni.com', '$2b$10$hsgmFedchPEouVcYhoLQFu6pVugIl4s3ACShW/LmizO6DOq96R8/m', 'Admin Nyeni', 0, 1, 1, 1, NULL, 'admin'),
('4b64076b-027b-4503-b820-dbb1a5492f5a', 'atta@gmail.com', '$2b$10$VPTl6Aap39B1nulRgLLtHukooYmnFEOFuwAFGz2Ojzd5f3NSFPfXK', 'atta', 0, 1, 1, 1, NULL, 'user'),
('e7deb8ca-6233-4859-a44e-d8587088604a', 'akmal@gmail.com', '$2b$10$2emVlIQXBFmpgO.MToFxieTsdO2nY57YeUEGi.cXw1AA2/kI25ACG', 'akmal', 0, 1, 1, 1, NULL, 'user');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `events`
--
ALTER TABLE `events`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `game_scores`
--
ALTER TABLE `game_scores`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `tickets`
--
ALTER TABLE `tickets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `tpm_feedbacks`
--
ALTER TABLE `tpm_feedbacks`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `events`
--
ALTER TABLE `events`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `game_scores`
--
ALTER TABLE `game_scores`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `tpm_feedbacks`
--
ALTER TABLE `tpm_feedbacks`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `game_scores`
--
ALTER TABLE `game_scores`
  ADD CONSTRAINT `game_scores_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `tickets`
--
ALTER TABLE `tickets`
  ADD CONSTRAINT `tickets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
