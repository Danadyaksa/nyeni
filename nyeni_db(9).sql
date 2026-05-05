-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: May 05, 2026 at 07:54 AM
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
  `event_start_date` date DEFAULT NULL,
  `event_end_date` date DEFAULT NULL,
  `open_time` time DEFAULT NULL,
  `close_time` time DEFAULT NULL,
  `location` varchar(255) NOT NULL,
  `price` int(11) DEFAULT 0,
  `early_bird_price` int(11) DEFAULT NULL,
  `early_bird_start` datetime DEFAULT NULL,
  `early_bird_end` datetime DEFAULT NULL,
  `regular_start` datetime DEFAULT NULL,
  `regular_end` datetime DEFAULT NULL,
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

INSERT INTO `events` (`id`, `title`, `category`, `event_date`, `event_start_date`, `event_end_date`, `open_time`, `close_time`, `location`, `price`, `early_bird_price`, `early_bird_start`, `early_bird_end`, `regular_start`, `regular_end`, `image_url`, `description`, `created_at`, `early_bird_deadline`, `latitude`, `longitude`, `is_active`) VALUES
(1, 'Konser Nyeni Fest 2026', 'Konser', '17 Mei 2026', '2026-05-17', NULL, '08:00:00', '20:00:00', 'JEC Yogyakarta', 150000, NULL, NULL, '2026-05-08 00:00:00', '2026-05-03 00:00:00', '2026-05-17 00:00:00', 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?q=80&w=400&auto=format&fit=crop', 'Konser paling nyeni se-Jogja! Bintang tamu rahasia.', '2026-04-29 20:39:25', '2026-05-10 23:59:59', -7.78700002, 110.37521414, 1),
(2, 'Teater Koma: Bunga Penutup', 'Teater', '29 April 2026', '2026-04-29', NULL, '08:00:00', '18:00:00', 'Taman Budaya Yogyakarta', 200000, NULL, NULL, '2026-03-27 00:00:00', '2026-04-27 00:00:00', '2026-05-14 00:00:00', '/uploads/avatar-1777829533233.jpg', 'Pementasan teater koma dengan lakon terbaru.', '2026-04-29 20:39:25', '2026-04-01 23:59:59', -7.78596270, 110.36032676, 1),
(4, 'Indie Gigs Vol. 4', 'Konser', '10 - 20 Mei 2026', '2026-05-10', '2026-05-20', '08:00:00', '20:00:00', 'Liquid Bar Jogja', 75000, NULL, NULL, NULL, '2026-05-01 00:00:00', '2026-05-21 00:00:00', 'https://images.unsplash.com/photo-1526478806334-5fd488fcaabc?q=80&w=400&auto=format&fit=crop', 'Gigs intim bareng band indie pujaan kampus.', '2026-04-29 20:39:25', NULL, -7.77862595, 110.39390573, 1),
(5, 'Stand Up Comedy JGJ', 'Stand Up', '7 - 18 Mei 2026', '2026-05-07', '2026-05-18', NULL, NULL, 'Auditorium UPN Veteran', 100000, 50000, '2026-04-18 00:00:00', '2026-05-06 00:00:00', '2026-05-07 00:00:00', '2026-05-18 00:00:00', '/uploads/avatar-1777829478758.heif', 'Ketawa sampe ngompol bareng komika-komika ibukota.', '2026-04-29 20:39:25', NULL, -7.76269190, 110.40922150, 1),
(8, 'a wee eheheh', 'Workshop', '10 Mei 2026', '2026-05-10', NULL, '07:00:00', '16:00:00', 'aoaeheh', 12454, NULL, NULL, NULL, '2026-05-03 00:00:00', '2026-05-10 00:00:00', '/uploads/avatar-1777829509237.jpg', 'aa', '2026-05-01 19:34:31', NULL, -7.78797505, 110.39784077, 1),
(9, 'tes apus', 'Konser', '29 April 2026', '2026-04-29', NULL, '08:00:00', '20:00:00', 'kos apis', 50000, NULL, NULL, NULL, NULL, NULL, '/uploads/avatar-1777829494195.jpg', 'nyanyi ajah', '2026-05-03 09:26:30', NULL, -7.77448238, 110.41825665, 1),
(13, 'tes', 'Konser', '14 Mei 2026', NULL, NULL, NULL, NULL, 'ggg', 25000, NULL, NULL, NULL, NULL, NULL, '/uploads/avatar-1777847580248.jpg', '', '2026-05-03 22:33:00', NULL, -7.79575986, 110.37076405, 1),
(14, 'bshshs', 'Konser', '10 Mei 2026', NULL, NULL, NULL, NULL, 'babababa', 10000, NULL, NULL, NULL, NULL, NULL, '/uploads/avatar-1777848692562.jpg', 'sjdjdj', '2026-05-03 22:51:32', NULL, -7.79955691, 110.36928152, 1);

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
(2, '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Atilla Danady', 'Labirin Gyro', 2, 3, '2026-04-30 19:45:57'),
(3, '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Atilla Danady', 'Labirin Gyro', 3, 3, '2026-05-01 12:06:23'),
(4, '467056e7-6471-49de-84a7-6cc46c9265ed', 'akmal', 'Labirin Gyro', 1, 7, '2026-05-01 22:06:52'),
(5, '467056e7-6471-49de-84a7-6cc46c9265ed', 'akmal', 'Labirin Gyro', 2, 1, '2026-05-01 22:07:03'),
(6, '467056e7-6471-49de-84a7-6cc46c9265ed', 'akmal', 'Labirin Gyro', 3, 2, '2026-05-01 22:07:10'),
(7, '467056e7-6471-49de-84a7-6cc46c9265ed', 'akmal', 'Labirin Gyro', 4, 13, '2026-05-01 22:17:24'),
(8, '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Atilla Danady', 'Labirin Gyro', 4, 5, '2026-05-02 02:03:23');

-- --------------------------------------------------------

--
-- Table structure for table `tickets`
--

CREATE TABLE `tickets` (
  `id` varchar(50) NOT NULL,
  `transaction_id` varchar(50) DEFAULT NULL,
  `user_id` varchar(50) DEFAULT NULL,
  `event_name` varchar(150) DEFAULT NULL,
  `event_date` varchar(50) DEFAULT NULL,
  `status` varchar(20) DEFAULT 'ACTIVE',
  `unique_code` int(3) DEFAULT NULL,
  `service_fee` int(11) DEFAULT 2500,
  `ticket_price` int(11) DEFAULT 0,
  `total_amount` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tickets`
--

INSERT INTO `tickets` (`id`, `transaction_id`, `user_id`, `event_name`, `event_date`, `status`, `unique_code`, `service_fee`, `ticket_price`, `total_amount`, `created_at`) VALUES
('01564052-da97-4111-9f00-556df85fd896', '75a5adf3-29f5-4ba6-9ce9-0a0e8eeb8b8b', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'a - Reguler', '16 Mei 2026', 'ACTIVE', 860, 0, 12454, 0, '2026-05-03 08:43:57'),
('0466ec73-69aa-4aef-a600-849757d293f0', '64fa899e-fe60-48fd-ae2b-9524305d23a9', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '8 - 19 Mei 2026', 'ACTIVE', 423, 2500, 50000, 102923, '2026-05-03 04:24:57'),
('072fd8ca-d9d0-43c7-904d-a58c4d883e87', 'd09465bf-8e0a-48eb-aed4-40a57ba789aa', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'bshshs - Reguler', '10 Mei 2026', 'ACTIVE', 998, 0, 10000, 0, '2026-05-04 03:48:28'),
('0ab65dd4-1606-4e6c-9a1f-1c6cd1750f4d', NULL, '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '20 - 31 Mei 2026', 'DECLINED', 515, 2500, 50000, 153015, '2026-04-30 23:12:13'),
('1327b6a7-b294-4aa3-8a86-d81552912c74', 'f2fb4b15-472e-465c-b283-1fb9820f3cfd', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Indie Gigs Vol. 4 - Reguler', '10 - 20 Mei 2026', 'ACTIVE', 141, 0, 75000, 0, '2026-05-03 22:27:04'),
('136204fb-7806-473a-864f-a072b99c6b11', 'b4d6ae70-4bd7-4bcb-afc1-49486157f0e6', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'tes apus - Reguler', '4 Mei 2026', 'EXPIRED', 150, 2500, 50000, 102650, '2026-05-03 09:27:28'),
('143944b8-0b1f-4ddf-beb6-09e10f43b2e0', '7b852e2c-ea76-404a-a55f-bd2d0431ef0c', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '20 - 31 Mei 2026', 'ACTIVE', 963, 0, 50000, 0, '2026-05-01 12:16:18'),
('14de43dd-b871-4481-a0bb-2cdcc273a037', NULL, '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '20 - 31 Mei 2026', 'DECLINED', 840, 2500, 50000, 153340, '2026-04-30 23:18:48'),
('190c4c07-43c5-4a9a-87a0-eb9ca9c7c53a', 'c42615d1-d1d7-49cc-a326-4e15240d41c9', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'a - Reguler', '14 Mei 2026', 'ACTIVE', 802, 0, 12454, 0, '2026-05-03 13:28:25'),
('1ef5d446-72f0-4881-b464-cd094ba9a28b', '7b0da82a-d5c6-40da-826a-c544ddf463a8', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'a - Reguler', '16 Mei 2026', 'ACTIVE', 219, 2500, 12454, 52535, '2026-05-03 08:45:18'),
('23340b49-0c57-4564-a178-9fd31d31db05', 'cb850b76-9d86-427d-8ec8-ac46d068606b', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '7 - 18 Mei 2026', 'DECLINED', 127, 2500, 50000, 52627, '2026-05-03 22:26:53'),
('277a71d4-733d-4124-af2b-0d4ebbbc72ad', '64fa899e-fe60-48fd-ae2b-9524305d23a9', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '8 - 19 Mei 2026', 'ACTIVE', 423, 0, 50000, 0, '2026-05-03 04:24:57'),
('294f7246-c7a8-4e0f-b0ee-0df8ed3bf400', 'dc32ec53-385d-4648-b4c0-e5202bdbc131', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '16 - 27 Mei 2026', 'ACTIVE', 607, 2500, 50000, 153107, '2026-05-01 19:26:30'),
('2972c102-4519-4d80-b165-8c04e7df08fc', NULL, '4b64076b-027b-4503-b820-dbb1a5492f5a', 'Indie Music Fest', '10 Juni 2026', 'DECLINED', NULL, 2500, 0, 0, '2026-04-29 20:21:09'),
('2a561169-f430-4a73-b510-39fab9696577', '7b0da82a-d5c6-40da-826a-c544ddf463a8', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'a - Reguler', '16 Mei 2026', 'ACTIVE', 219, 0, 12454, 0, '2026-05-03 08:45:18'),
('2d99405c-f196-4f36-8b6c-9337c09f8dab', '7b0da82a-d5c6-40da-826a-c544ddf463a8', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'a - Reguler', '16 Mei 2026', 'ACTIVE', 219, 0, 12454, 0, '2026-05-03 08:45:18'),
('32c64d95-8efb-4865-a261-e3ecd3e76b8f', 'e16751d4-9db8-4e99-a761-be1a1ffda738', '467056e7-6471-49de-84a7-6cc46c9265ed', 'Konser Nyeni Fest 2026 - Normal', '12 Mei 2026', 'ACTIVE', 680, 2500, 150000, 153180, '2026-05-01 20:47:30'),
('347675ee-d28e-4415-b88a-100951eea6cd', '0efafe48-c6b0-4484-b8d0-ad400ffa0ab7', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'a - Reguler', '16 Mei 2026', 'ACTIVE', 405, 0, 12454, 0, '2026-05-03 04:28:00'),
('3f8a452c-2edf-4e85-95c9-62eb3b0e8a97', '6f06ca71-9450-4edb-91f2-c174690aac3f', '9dab964c-1091-42ad-aee4-02dd223d2add', 'bshshs - Reguler', '10 Mei 2026', 'ACTIVE', 132, 2500, 10000, 12632, '2026-05-05 05:45:19'),
('41d301f6-7290-4b06-9888-1e8ca3ae6106', '987dab29-cbcf-40d2-8739-3937849a019d', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Indie Gigs Vol. 4 - Reguler', '10 - 20 Mei 2026', 'DECLINED', 405, 2500, 75000, 152905, '2026-05-05 05:09:52'),
('42480f5a-ed93-4ca8-9e1b-f04170eb8157', '065ff58c-2dfb-48ef-9d7f-f1b8fe8b8796', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '20 - 31 Mei 2026', 'ACTIVE', 916, 2500, 50000, 103416, '2026-04-30 23:49:36'),
('431fe32a-32c5-46bf-a867-09f5271a8422', NULL, '4b64076b-027b-4503-b820-dbb1a5492f5a', 'ARTJOG 2026: Motif', '25 Mei - 25 Juli 2026', 'USED', NULL, 2500, 0, 0, '2026-04-29 20:08:37'),
('445fab45-a5a9-41e6-9bc4-44daa9fe60a9', '5c9bbe60-5f1b-4dbf-b2c1-7592502f78d5', '467056e7-6471-49de-84a7-6cc46c9265ed', 'a - Normal', '17 Mei 2026', 'ACTIVE', 651, 0, 12454, 0, '2026-05-01 20:52:19'),
('453821db-a9fb-4789-a9bf-71de220aef1e', NULL, '4b64076b-027b-4503-b820-dbb1a5492f5a', 'Stand Up Comedy JGJ', '22 Jun 2026', '', NULL, 2500, 0, 0, '2026-04-29 21:15:37'),
('455567fa-8e12-4737-8f51-25526005a4ec', NULL, '4b64076b-027b-4503-b820-dbb1a5492f5a', 'ARTJOG 2026: Motif', '25 Mei - 25 Juli 2026', 'DECLINED', NULL, 2500, 0, 0, '2026-04-29 20:01:16'),
('47c3a31d-7763-418f-be51-7fd919bd84dc', '042762b7-5099-40c7-9686-fa05ff7747fd', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '8 - 19 Mei 2026', 'ACTIVE', 194, 2500, 50000, 152694, '2026-05-03 01:21:44'),
('48cf60ea-ec9f-42a1-a107-68373ff09a92', NULL, '4b64076b-027b-4503-b820-dbb1a5492f5a', 'ARTJOG 2026: Motif', '25 Mei - 25 Juli 2026', 'DECLINED', NULL, 2500, 0, 0, '2026-04-29 20:11:25'),
('493f2e39-53db-46a7-a53c-a22f8eed384c', 'bc2ec1b5-2975-422f-8ac5-e26abb836912', '2fc6d0e8-44db-11f1-8a7c-0a0027000005', 'Stand Up Comedy JGJ - Early Bird', '16 - 27 Mei 2026', 'ACTIVE', 502, 0, 50000, 0, '2026-05-01 19:22:29'),
('49e28666-e130-4d3c-b6b4-fd005403aa10', '5c9bbe60-5f1b-4dbf-b2c1-7592502f78d5', '467056e7-6471-49de-84a7-6cc46c9265ed', 'a - Normal', '17 Mei 2026', 'ACTIVE', 651, 0, 12454, 0, '2026-05-01 20:52:19'),
('4b325566-1b26-4b92-9274-039433e3a614', 'e2adfc4b-0dcc-4cb7-9f71-81a69e5c1d48', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '20 - 31 Mei 2026', 'ACTIVE', 185, 0, 50000, 0, '2026-05-01 18:31:26'),
('4b3f1209-9876-4000-a179-eb9540478ed1', '065ff58c-2dfb-48ef-9d7f-f1b8fe8b8796', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '20 - 31 Mei 2026', 'ACTIVE', 916, 0, 50000, 0, '2026-04-30 23:49:36'),
('4c5a06ba-1dd0-4f38-adda-12faa7d5d396', 'fe5fbfb4-5901-472d-bd9b-5dcaa2387c08', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'tes y - Reguler', '4 Mei 2026', 'EXPIRED', 129, 2500, 100000, 102629, '2026-05-03 13:03:17'),
('4cd81142-611a-4e5e-8b01-87828cc77eb6', 'c9bb9602-c349-4c88-b2c4-995298050d7e', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '7 - 18 Mei 2026', 'DECLINED', 183, 0, 50000, 0, '2026-05-05 04:40:24'),
('4faf55ac-ba7c-4199-bb30-84b61865a195', NULL, '4b64076b-027b-4503-b820-dbb1a5492f5a', 'ARTJOG 2026: Motif', '25 Mei - 25 Juli 2026', 'DECLINED', NULL, 2500, 0, 0, '2026-04-29 20:08:07'),
('55a58816-d6d8-4e5a-bb32-0025e94ee441', 'e2adfc4b-0dcc-4cb7-9f71-81a69e5c1d48', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '20 - 31 Mei 2026', 'ACTIVE', 185, 0, 50000, 0, '2026-05-01 18:31:26'),
('568d284b-5bc1-4de2-902e-70d96bf4c293', 'b47c2548-dff1-4448-b916-990a37eb7849', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '20 - 31 Mei 2026', 'ACTIVE', 568, 0, 50000, 0, '2026-04-30 23:25:57'),
('57c97156-3a9b-42f1-948d-262fa2bb610a', NULL, '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Normal', '22 Jun 2026', 'EXPIRED', NULL, 2500, 0, 0, '2026-04-30 21:52:38'),
('58d00160-aed6-47e4-9f09-c1db41f4fee1', '0efafe48-c6b0-4484-b8d0-ad400ffa0ab7', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'a - Reguler', '16 Mei 2026', 'ACTIVE', 405, 0, 12454, 0, '2026-05-03 04:28:00'),
('59efd7e4-a50d-4abc-bc4c-50ed5f885de2', '3df8f81c-8ea1-4f0d-a076-01dc37968b11', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'a - Reguler', '16 Mei 2026', 'ACTIVE', 87, 2500, 12454, 27495, '2026-05-03 08:36:16'),
('5e22c033-164f-4360-a0a0-6748bf9eb570', 'b2a23b12-9a43-47fc-80bc-7cb20bbf89b4', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'abc - Normal', '10 Mei 2026', 'ACTIVE', 182, 2500, 120000, 362682, '2026-05-01 18:45:45'),
('61657ed1-7c9e-4249-b903-833dfcbe1838', '7b852e2c-ea76-404a-a55f-bd2d0431ef0c', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '20 - 31 Mei 2026', 'ACTIVE', 963, 2500, 50000, 153463, '2026-05-01 12:16:18'),
('617c50fe-77f9-436a-9bcc-a1cb791fa7dc', '987dab29-cbcf-40d2-8739-3937849a019d', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Indie Gigs Vol. 4 - Reguler', '10 - 20 Mei 2026', 'DECLINED', 405, 0, 75000, 0, '2026-05-05 05:09:52'),
('64fee4c4-6ff8-437e-93c9-74c007da696d', 'e2adfc4b-0dcc-4cb7-9f71-81a69e5c1d48', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '20 - 31 Mei 2026', 'ACTIVE', 185, 0, 50000, 0, '2026-05-01 18:31:26'),
('6a5ec335-6daa-43f0-9e4a-eb298b79e7f8', '406d6678-b782-4be6-aa2c-0df749cc324c', '9dab964c-1091-42ad-aee4-02dd223d2add', 'Stand Up Comedy JGJ - Early Bird', '7 - 18 Mei 2026', 'ACTIVE', 544, 0, 50000, 0, '2026-05-05 05:35:46'),
('6c8a5e57-7591-4135-a918-fcb12de465ec', '75a5adf3-29f5-4ba6-9ce9-0a0e8eeb8b8b', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'a - Reguler', '16 Mei 2026', 'ACTIVE', 860, 2500, 12454, 65630, '2026-05-03 08:43:57'),
('6ef6f092-46c5-4b9c-a2a3-e7bd4d6cd720', '042762b7-5099-40c7-9686-fa05ff7747fd', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '8 - 19 Mei 2026', 'EXPIRED', 194, 0, 50000, 0, '2026-05-03 01:21:44'),
('70627f6c-78cb-4f15-ac56-cbcdfb5ae1af', '85ccb114-5164-4346-af21-c0618a835e3e', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '8 - 19 Mei 2026', 'ACTIVE', 32, 2500, 50000, 102532, '2026-05-03 14:58:09'),
('7161afce-f9cf-477d-ba75-86141d33b1c6', 'de98119c-70ab-4ef4-83cd-6336f9f9fc2a', '9dab964c-1091-42ad-aee4-02dd223d2add', 'Indie Gigs Vol. 4 - Reguler', '10 - 20 Mei 2026', 'DECLINED', 745, 2500, 75000, 78245, '2026-05-05 05:48:10'),
('79544148-f9b0-485d-80ff-7c5e27055e5f', 'c42615d1-d1d7-49cc-a326-4e15240d41c9', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'a - Reguler', '14 Mei 2026', 'ACTIVE', 802, 2500, 12454, 65572, '2026-05-03 13:28:25'),
('7a8e95e7-dd55-4ea9-8159-f8c9bf2c8a0e', 'f04a29fd-949b-4da5-8d9a-ff62cc3039fb', '9dab964c-1091-42ad-aee4-02dd223d2add', 'Stand Up Comedy JGJ - Early Bird', '7 - 18 Mei 2026', 'PENDING', 308, 2500, 50000, 52808, '2026-05-05 05:52:43'),
('7dbcfa0b-e119-47c1-8909-ad99374e85cf', NULL, '4b64076b-027b-4503-b820-dbb1a5492f5a', 'ARTJOG 2026: Motif', '25 Mei - 25 Juli 2026', 'DECLINED', NULL, 2500, 0, 0, '2026-04-29 20:08:29'),
('7f6c4f3b-8fb5-4813-a463-2997ecacc8e2', 'c9bb9602-c349-4c88-b2c4-995298050d7e', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '7 - 18 Mei 2026', 'DECLINED', 183, 2500, 50000, 102683, '2026-05-05 04:40:24'),
('80fbda4b-93cd-489b-a0d7-89d4627fae16', 'b4d6ae70-4bd7-4bcb-afc1-49486157f0e6', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'tes apus - Reguler', '4 Mei 2026', 'EXPIRED', 150, 0, 50000, 0, '2026-05-03 09:27:28'),
('828b0890-ce60-417a-8da7-bc60c36f8d67', 'b47c2548-dff1-4448-b916-990a37eb7849', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '20 - 31 Mei 2026', 'ACTIVE', 568, 0, 50000, 0, '2026-04-30 23:25:57'),
('828dc898-ff31-49ce-b988-a74f80cd9e56', '75a5adf3-29f5-4ba6-9ce9-0a0e8eeb8b8b', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'a - Reguler', '16 Mei 2026', 'ACTIVE', 860, 0, 12454, 0, '2026-05-03 08:43:57'),
('84c93833-6b02-4843-bce8-23e5624a8cd6', '9d636486-b002-473d-aa63-f634ce92a254', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Indie Gigs Vol. 4 - Reguler', '10 - 20 Mei 2026', 'ACTIVE', 911, 2500, 75000, 153411, '2026-05-03 08:38:48'),
('8a43504c-4cfb-440a-b0d5-760a9c2e8121', 'f2fb4b15-472e-465c-b283-1fb9820f3cfd', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Indie Gigs Vol. 4 - Reguler', '10 - 20 Mei 2026', 'ACTIVE', 141, 2500, 75000, 227641, '2026-05-03 22:27:04'),
('8acb73df-aa10-4f27-97e9-38dc5b9164a5', '406d6678-b782-4be6-aa2c-0df749cc324c', '9dab964c-1091-42ad-aee4-02dd223d2add', 'Stand Up Comedy JGJ - Early Bird', '7 - 18 Mei 2026', 'ACTIVE', 544, 0, 50000, 0, '2026-05-05 05:35:46'),
('8b9d8d67-7b02-4c92-bda5-dab6fca29af7', NULL, '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Normal', '20 - 31 Mei 2026', 'ACTIVE', 259, 2500, 100000, 102759, '2026-04-30 23:00:21'),
('8f567e5c-2093-4eb1-802a-ada0a3bf987b', '7b0da82a-d5c6-40da-826a-c544ddf463a8', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'a - Reguler', '16 Mei 2026', 'ACTIVE', 219, 0, 12454, 0, '2026-05-03 08:45:18'),
('8f89ca67-35ce-404f-8eb6-2ff0aa9969e6', 'd09465bf-8e0a-48eb-aed4-40a57ba789aa', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'bshshs - Reguler', '10 Mei 2026', 'ACTIVE', 998, 0, 10000, 0, '2026-05-04 03:48:28'),
('94ece0be-4dfa-48f9-9f79-eb142c205d0b', NULL, '4b64076b-027b-4503-b820-dbb1a5492f5a', 'ARTJOG 2026: Motif', '25 Mei - 25 Juli 2026', 'DECLINED', NULL, 2500, 0, 0, '2026-04-29 20:05:26'),
('95855f7b-2a51-42d3-8695-872e8708fc34', 'e2adfc4b-0dcc-4cb7-9f71-81a69e5c1d48', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '20 - 31 Mei 2026', 'ACTIVE', 185, 2500, 50000, 252685, '2026-05-01 18:31:26'),
('98cb83a7-e730-4835-8a54-38b515f3b579', NULL, '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '20 - 31 Mei 2026', 'DECLINED', 840, 0, 50000, 0, '2026-04-30 23:18:48'),
('99158019-1eee-4ec3-8cc2-25b78864fc11', NULL, '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '20 - 31 Mei 2026', 'DECLINED', 840, 0, 50000, 0, '2026-04-30 23:18:48'),
('9a9b6291-2b1a-4ac9-b1a8-7c95931d4d8e', 'dc32ec53-385d-4648-b4c0-e5202bdbc131', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '16 - 27 Mei 2026', 'ACTIVE', 607, 0, 50000, 0, '2026-05-01 19:26:30'),
('9e26dd3b-d5e1-4473-8e96-9ab74bb6f0e9', '042762b7-5099-40c7-9686-fa05ff7747fd', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '8 - 19 Mei 2026', 'ACTIVE', 194, 0, 50000, 0, '2026-05-03 01:21:44'),
('a0c764f3-64ef-45a0-a283-614137f29666', '0efafe48-c6b0-4484-b8d0-ad400ffa0ab7', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'a - Reguler', '16 Mei 2026', 'ACTIVE', 405, 2500, 12454, 40267, '2026-05-03 04:28:00'),
('a2054fa4-c317-45df-af8b-20c1549a2a4f', NULL, '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '20 - 31 Mei 2026', 'DECLINED', 515, 0, 50000, 0, '2026-04-30 23:12:13'),
('a37aa619-e649-4cac-8699-44d8de61f2ba', '7b852e2c-ea76-404a-a55f-bd2d0431ef0c', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '20 - 31 Mei 2026', 'ACTIVE', 963, 0, 50000, 0, '2026-05-01 12:16:18'),
('a54ed3a2-e213-41b2-be7d-02d286bc3e20', '406d6678-b782-4be6-aa2c-0df749cc324c', '9dab964c-1091-42ad-aee4-02dd223d2add', 'Stand Up Comedy JGJ - Early Bird', '7 - 18 Mei 2026', 'ACTIVE', 544, 2500, 50000, 153044, '2026-05-05 05:35:46'),
('a985a174-8a69-4bea-8cf2-b1fc0f5c72a3', 'e2adfc4b-0dcc-4cb7-9f71-81a69e5c1d48', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '20 - 31 Mei 2026', 'ACTIVE', 185, 0, 50000, 0, '2026-05-01 18:31:26'),
('aa65c144-b35c-4000-b89e-15f6905c24bd', 'bc2ec1b5-2975-422f-8ac5-e26abb836912', '2fc6d0e8-44db-11f1-8a7c-0a0027000005', 'Stand Up Comedy JGJ - Early Bird', '16 - 27 Mei 2026', 'ACTIVE', 502, 0, 50000, 0, '2026-05-01 19:22:29'),
('af1100a0-50cb-4d3a-b432-24d856a360af', '75a5adf3-29f5-4ba6-9ce9-0a0e8eeb8b8b', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'a - Reguler', '16 Mei 2026', 'ACTIVE', 860, 0, 12454, 0, '2026-05-03 08:43:57'),
('b071e89a-e21e-49e7-aae9-5ef86a3c4bc4', 'd09465bf-8e0a-48eb-aed4-40a57ba789aa', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'bshshs - Reguler', '10 Mei 2026', 'ACTIVE', 998, 2500, 10000, 33498, '2026-05-04 03:48:28'),
('b9075283-a365-4a99-9b3e-e6fb84869cc7', '82698ea0-5252-4acb-9cd7-8fef280b5446', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'bshshs - Reguler', '10 Mei 2026', 'ACTIVE', 126, 2500, 10000, 22626, '2026-05-04 20:21:25'),
('ba872bd8-e5b1-45a5-a501-e4b4a3b17335', 'dc32ec53-385d-4648-b4c0-e5202bdbc131', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '16 - 27 Mei 2026', 'ACTIVE', 607, 0, 50000, 0, '2026-05-01 19:26:30'),
('bb823c37-0181-4313-8612-fce3e7823f1e', '9d636486-b002-473d-aa63-f634ce92a254', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Indie Gigs Vol. 4 - Reguler', '10 - 20 Mei 2026', 'ACTIVE', 911, 0, 75000, 0, '2026-05-03 08:38:48'),
('c1333891-5dc6-409b-9450-ff7a7ae401df', 'c42615d1-d1d7-49cc-a326-4e15240d41c9', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'a - Reguler', '14 Mei 2026', 'ACTIVE', 802, 0, 12454, 0, '2026-05-03 13:28:25'),
('c468ba37-ca6e-484e-842d-a5e644426612', 'c42615d1-d1d7-49cc-a326-4e15240d41c9', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'a - Reguler', '14 Mei 2026', 'ACTIVE', 802, 0, 12454, 0, '2026-05-03 13:28:25'),
('c78fa6ee-cd7b-442a-a709-e35aac822c4f', 'bc2ec1b5-2975-422f-8ac5-e26abb836912', '2fc6d0e8-44db-11f1-8a7c-0a0027000005', 'Stand Up Comedy JGJ - Early Bird', '16 - 27 Mei 2026', 'ACTIVE', 502, 2500, 50000, 153002, '2026-05-01 19:22:29'),
('c7b156b2-1a03-4371-8437-a2159cb87228', 'b47c2548-dff1-4448-b916-990a37eb7849', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '20 - 31 Mei 2026', 'ACTIVE', 568, 2500, 50000, 153068, '2026-04-30 23:25:57'),
('c8181f09-1175-4c35-bc69-694b91af3c3b', '82698ea0-5252-4acb-9cd7-8fef280b5446', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'bshshs - Reguler', '10 Mei 2026', 'ACTIVE', 126, 0, 10000, 0, '2026-05-04 20:21:25'),
('d04d577b-380c-476c-8baa-6d658e1703f2', 'b2a23b12-9a43-47fc-80bc-7cb20bbf89b4', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'abc - Normal', '10 Mei 2026', 'ACTIVE', 182, 0, 120000, 0, '2026-05-01 18:45:45'),
('d38c73c0-9d3e-4568-b7dd-337eb0b1d8b2', NULL, '4b64076b-027b-4503-b820-dbb1a5492f5a', 'Indie Music Fest', '10 Juni 2026', 'DECLINED', NULL, 2500, 0, 0, '2026-04-29 20:12:19'),
('d3cb128b-9071-418d-a2ec-bd6b5147c4a5', 'd6d55251-fe8d-4c78-afa8-ea2d32ff11e7', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Pameran Lukis Senja - Normal', '01 Jun 2026', 'ACTIVE', 224, 0, 50000, 0, '2026-05-01 18:56:39'),
('d477ee0d-e2fc-47cf-9430-33c740ead5f6', 'f2fb4b15-472e-465c-b283-1fb9820f3cfd', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Indie Gigs Vol. 4 - Reguler', '10 - 20 Mei 2026', 'ACTIVE', 141, 0, 75000, 0, '2026-05-03 22:27:04'),
('d526099c-fd9f-43e9-ae44-65279a35013a', '3df8f81c-8ea1-4f0d-a076-01dc37968b11', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'a - Reguler', '16 Mei 2026', 'EXPIRED', 87, 0, 12454, 0, '2026-05-03 08:36:16'),
('dffb2da9-da36-4afb-885c-3c68e5f257ed', '5c9bbe60-5f1b-4dbf-b2c1-7592502f78d5', '467056e7-6471-49de-84a7-6cc46c9265ed', 'a - Normal', '17 Mei 2026', 'ACTIVE', 651, 2500, 12454, 52967, '2026-05-01 20:52:19'),
('e03e755e-e527-45b3-9bee-f9fba75d4c89', 'd6d55251-fe8d-4c78-afa8-ea2d32ff11e7', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Pameran Lukis Senja - Normal', '01 Jun 2026', 'ACTIVE', 224, 0, 50000, 0, '2026-05-01 18:56:39'),
('e1d501de-0171-4fac-99c9-7a795d77d8f8', NULL, '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '20 - 31 Mei 2026', 'DECLINED', 515, 0, 50000, 0, '2026-04-30 23:12:13'),
('e48bd0c7-6af0-4d82-bb3b-8d81a2d5ff2c', NULL, '4b64076b-027b-4503-b820-dbb1a5492f5a', 'ARTJOG 2026: Motif', '25 Mei - 25 Juli 2026', 'DECLINED', NULL, 2500, 0, 0, '2026-04-29 20:11:02'),
('e4fe59ee-dcdf-433c-8f08-934ab152f882', '75a5adf3-29f5-4ba6-9ce9-0a0e8eeb8b8b', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'a - Reguler', '16 Mei 2026', 'ACTIVE', 860, 0, 12454, 0, '2026-05-03 08:43:57'),
('ed5d727c-6558-457c-a329-0e9c9596d43d', 'c42615d1-d1d7-49cc-a326-4e15240d41c9', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'a - Reguler', '14 Mei 2026', 'ACTIVE', 802, 0, 12454, 0, '2026-05-03 13:28:25'),
('f36be206-0553-43c2-a19a-4a928b49586c', 'd6d55251-fe8d-4c78-afa8-ea2d32ff11e7', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Pameran Lukis Senja - Normal', '01 Jun 2026', 'ACTIVE', 224, 2500, 50000, 152724, '2026-05-01 18:56:39'),
('f89a3cf7-8380-4478-b417-7828b3a09056', '5c9bbe60-5f1b-4dbf-b2c1-7592502f78d5', '467056e7-6471-49de-84a7-6cc46c9265ed', 'a - Normal', '17 Mei 2026', 'ACTIVE', 651, 0, 12454, 0, '2026-05-01 20:52:19'),
('f9aa9d11-62e6-4d97-892d-96923ab72bdf', 'b2a23b12-9a43-47fc-80bc-7cb20bbf89b4', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'abc - Normal', '10 Mei 2026', 'ACTIVE', 182, 0, 120000, 0, '2026-05-01 18:45:45'),
('fa13b8e3-502e-460a-87dd-b911aadb2ef8', '85ccb114-5164-4346-af21-c0618a835e3e', '1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'Stand Up Comedy JGJ - Early Bird', '8 - 19 Mei 2026', 'ACTIVE', 32, 0, 50000, 0, '2026-05-03 14:58:09'),
('ff8b035a-9df7-4bfb-9189-3569e7efc1f3', NULL, '4b64076b-027b-4503-b820-dbb1a5492f5a', 'ARTJOG 2026: Motif', '25 Mei - 25 Juli 2026', 'ACTIVE', NULL, 2500, 0, 0, '2026-04-29 19:53:16');

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
('16726f56-6ba4-4cea-bc9d-00d3d1b176a4', 'aksa2@gmail.com', '$2b$10$6rOCs.NzEzdTOC9s0nh/4utYOtkDK.9HKcuTqPobSBIhaR7UWpRra', 'aksa2', 0, 1, 1, 1, NULL, 'user'),
('1702e6b1-fdec-46fe-8800-d8ef1b1578a8', 'aksa@gmail.com', '$2b$10$E078FCsfKdPs0OOAELjFi.GXqfgMdPM5/qwXAKZHyaMWju1YSC/Gq', 'aksa aja', 6300, 10, 4, 5, '/uploads/avatar-1777860686472.jpg', 'user'),
('2fc6d0e8-44db-11f1-8a7c-0a0027000005', 'admin@nyeni.com', '$2b$10$hsgmFedchPEouVcYhoLQFu6pVugIl4s3ACShW/LmizO6DOq96R8/m', 'Admin Nyeni', 0, 1, 1, 1, NULL, 'admin'),
('467056e7-6471-49de-84a7-6cc46c9265ed', 'yaya', '$2b$10$nIMcPWoL6mDvknankc8/HOrWJlH36Xw8hMGv267xMKvniPDqvyQaq', 'akmal', 650, 4, 1, 5, NULL, 'user'),
('4b64076b-027b-4503-b820-dbb1a5492f5a', 'atta@gmail.com', '$2b$10$VPTl6Aap39B1nulRgLLtHukooYmnFEOFuwAFGz2Ojzd5f3NSFPfXK', 'atta', 0, 1, 1, 1, NULL, 'user'),
('86bfc812-ee86-4bc2-a7a7-5e912c9e6220', 'apis@gmail.com', '$2b$10$BIFQeF9tfOBY/QBstB4wxOuI00D2UFh6I2xJHf7OcIaTozzbmkZIC', 'apis', 0, 1, 1, 1, NULL, 'user'),
('9dab964c-1091-42ad-aee4-02dd223d2add', 'atila@gmail.com', '$2b$10$O59izMt5X73ZDiStTndozeSwa5kSRzIP2jB6oYzghqIfgEOW0fWYK', 'atila', 600, 4, 1, 1, NULL, 'user'),
('b2b7ff65-63b2-40cf-a65b-ed0fa73c8196', 'akmall@gmail.com', '$2b$10$TbqQdK4S5Wsm1dG9EMT8qus/eAGp5Druj4uEIWf4W0X2ssSLXisB6', 'akmal', 0, 1, 1, 1, NULL, 'user'),
('c480a27e-7996-4ac6-b656-9542590dc08b', 'danang@gmail.com', '$2b$10$Hk1fYTu7gtiR.b2Xi/5yTuCfWKzOQtiWYNS.RCesvWnn05ClUi88a', 'danang', 0, 1, 1, 1, NULL, 'user'),
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
  ADD KEY `user_id` (`user_id`),
  ADD KEY `idx_transaction_id` (`transaction_id`);

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `game_scores`
--
ALTER TABLE `game_scores`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

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
