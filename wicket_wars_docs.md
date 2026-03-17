# Wicket Wars — Game Design Document

## Overview

Wicket Wars is a cricket strategy simulation mobile game built in Flutter. It is not an arcade game. Every match result is driven by player ratings, team composition, and weighted random algorithms. The focus is on squad building, strategic team selection, and real-time online competition.

---

## Core Concept

| Property | Detail |
|---|---|
| Platform | Mobile (Flutter) |
| Genre | Strategy / Simulation |
| Match Type | Algorithm-driven, not arcade |
| Multiplayer | Real-time 1v1 via Firebase Firestore |
| Theme | Dark, Material UI with game styling |

---

## Player System

### Real Players
- Based on actual cricketers (e.g. Babar Azam, Virat Kohli)
- Fixed ratings — cannot be changed or trained
- Stable stats across all matches
- Serve as premium anchor players in squads

### Custom Players
- Randomly generated with procedural names and stats
- AI-generated face or placeholder avatar
- Fully trainable — stats improve over time
- The primary progression mechanic of the game

### Player Attributes

Every player, real or custom, has six attributes:

| Attribute | Description |
|---|---|
| Batting | Determines scoring ability and shot quality |
| Bowling | Determines wicket-taking and economy rate |
| Fielding | Affects catches, run-outs, and boundary saves |
| Stamina | Degrades during long matches; affects late-game performance |
| Consistency | Controls variance in performance ball to ball |
| Overall | Weighted composite of all attributes |

---

## Squad System

- Each user maintains a squad of up to **15 players**
- Before every match, the user selects a **Playing XI** (11 players)
- Players in training are **unavailable** for selection
- Squad management is a core daily activity

---

## Training System

- Only **custom players** can be trained
- Each training session has a **countdown timer**
- Stats increase automatically when the timer completes
- A player under training cannot be added to the Playing XI
- Training adds strategic depth — you must plan around unavailability

---

## Match System

### How Simulation Works

Matches are not played manually. The algorithm simulates the match ball by ball based on:

- Batting ratings of the selected XI
- Bowling ratings of the opposing XI
- Team balance (all-rounders, specialist bowlers)
- Stamina levels at the time of the match
- A weighted random factor for realistic variance

### Match Output

Every completed match shows:

- Full scoreboard (runs, overs, wickets)
- Ball-by-ball commentary feed
- Wicket log with dismissal types
- Result summary (win / loss / margin)
- Coins and XP earned

---

## Real-Time 1v1 Multiplayer

This is the centrepiece feature of Wicket Wars.

### Flow

1. Player A creates a match room — receives a 6-character room code
2. Player B enters the code and joins the room
3. Both players lock their Playing XI independently
4. Once both squads are locked, simulation begins
5. Both screens receive live updates turn by turn
6. Match ends — result shown to both players simultaneously

### Turn Logic

- Each "turn" is one over (6 balls)
- Both users submit their bowling choice for that over
- Backend (Firestore) updates the shared match state
- Firestore real-time listeners push the update to both screens instantly
- No socket server needed — Firestore snapshots handle all sync

### Why Firestore

- Real-time listeners update both clients the moment state changes
- No polling, no delay
- Room state, score, commentary, and over data all live in one Firestore document
- Scales without a dedicated backend server

---

## Spectator / Viewer Mode

A third user can open any live match room and watch in real time.

### What Viewers Can See
- Live scoreboard
- Current over and ball-by-ball commentary
- Both team names and playing XIs
- Match progress and result

### What Viewers Cannot Do
- Interact with match state
- Submit any actions
- Affect the simulation in any way

### Implementation
Read-only Firestore listener on the match room document. The viewer screen is a stripped-down version of the match screen with all interactive elements removed.

---

## Online Features

### Firebase Services Used

| Service | Purpose |
|---|---|
| Firebase Auth | User accounts and login |
| Firestore | Squad data, match rooms, leaderboard, live sync |
| Cloud Functions (optional) | Match result validation, anti-cheat |

### Cloud-Synced Data
- User profile and stats
- Squad and player collection
- Match history
- Leaderboard rankings
- Coins balance

---

## Reward System

| Reward | Trigger |
|---|---|
| Coins | Winning or completing a match |
| Daily reward | Opening the app once per day |
| Match bonus | Winning a 1v1 multiplayer match |
| Training reward | Completing a training session |

Coins are used to unlock new custom players and cosmetic upgrades (future scope).

---

## App Screens

| # | Screen | Purpose |
|---|---|---|
| 1 | Splash Screen | App launch branding |
| 2 | Home Dashboard | Daily reward, quick match, news |
| 3 | Squad Screen | View and manage all 15 players |
| 4 | Player Detail | Full stats, training status, history |
| 5 | Training Screen | Start training, view timer, track progress |
| 6 | Match Lobby | Select Playing XI, confirm squad before match |
| 7 | Real-Time Match Screen | Live scoreboard, commentary, over tracker |
| 8 | Match Result | Final scorecard, coins earned, share result |
| 9 | Leaderboard | Global rankings by wins and rating |
| 10 | Profile | User stats, match history, account settings |
| 11 | Viewer Screen | Read-only live match for spectators |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| State Management | Riverpod or Provider |
| Local Storage | Hive or SharedPreferences |
| Backend / Auth | Firebase Auth |
| Database | Firebase Firestore |
| Real-Time Sync | Firestore real-time listeners |
| Navigation | go_router |

---

## Project Scope — MVP vs Full

### MVP (target by week 10)
- [ ] Player and squad system with local storage
- [ ] Custom player training with timer
- [ ] Match simulation algorithm
- [ ] Match screen with scoreboard and commentary
- [ ] Firebase auth and Firestore sync
- [ ] Real-time 1v1 multiplayer with room codes
- [ ] Basic leaderboard

### Full Version (weeks 11–12 and beyond)
- [ ] Real player data with fixed ratings
- [ ] Spectator / viewer mode
- [ ] Daily rewards and coin economy
- [ ] Match history and profile stats
- [ ] Dark theme polish and animations
- [ ] AI avatar generation for custom players

---

*Wicket Wars — built as a MAD Flutter course project.*
