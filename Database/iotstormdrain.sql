-- phpMyAdmin SQL Dump
-- version 4.9.5
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Mar 22, 2024 at 02:35 PM
-- Server version: 5.7.24
-- PHP Version: 7.4.1

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `iotstormdrain`
--

-- --------------------------------------------------------

--
-- Table structure for table `batlogs`
--

CREATE TABLE `batlogs` (
  `bat_id` int(20) NOT NULL,
  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `device_id` varchar(62) DEFAULT NULL,
  `app_id` varchar(62) DEFAULT NULL,
  `bat_lvl` int(11) DEFAULT NULL,
  `rssi` varchar(62) DEFAULT NULL,
  `snr` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `humiditylogs`
--

CREATE TABLE `humiditylogs` (
  `humidity_id` int(20) NOT NULL,
  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `device_id` varchar(62) DEFAULT NULL,
  `app_id` varchar(62) DEFAULT NULL,
  `humidity` int(11) DEFAULT NULL,
  `rssi` varchar(62) DEFAULT NULL,
  `snr` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `templogs`
--

CREATE TABLE `templogs` (
  `temp_id` int(20) NOT NULL,
  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `device_id` varchar(62) DEFAULT NULL,
  `app_id` varchar(62) DEFAULT NULL,
  `temperature` int(11) DEFAULT NULL,
  `rssi` varchar(62) DEFAULT NULL,
  `snr` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `waterlogs`
--

CREATE TABLE `waterlogs` (
  `waterlog_id` int(20) NOT NULL,
  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `device_id` varchar(62) DEFAULT NULL,
  `app_id` varchar(62) DEFAULT NULL,
  `frm_payload` varchar(62) DEFAULT NULL,
  `rssi` varchar(62) DEFAULT NULL,
  `snr` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


--
-- Indexes for table `batlogs`
--
ALTER TABLE `batlogs`
  ADD PRIMARY KEY (`bat_id`);

--
-- Indexes for table `humiditylogs`
--
ALTER TABLE `humiditylogs`
  ADD PRIMARY KEY (`humidity_id`);

--
-- Indexes for table `templogs`
--
ALTER TABLE `templogs`
  ADD PRIMARY KEY (`temp_id`);

--
-- Indexes for table `waterlogs`
--
ALTER TABLE `waterlogs`
  ADD PRIMARY KEY (`waterlog_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `batlogs`
--
ALTER TABLE `batlogs`
  MODIFY `bat_id` int(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `humiditylogs`
--
ALTER TABLE `humiditylogs`
  MODIFY `humidity_id` int(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `templogs`
--
ALTER TABLE `templogs`
  MODIFY `temp_id` int(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `waterlogs`
--
ALTER TABLE `waterlogs`
  MODIFY `waterlog_id` int(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
