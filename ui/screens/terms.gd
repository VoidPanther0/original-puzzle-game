extends Screen

const TEXT := """TEMPLATE - have this reviewed by a lawyer and fill in your company details before publishing.

1. Use of the game
You may play the game for personal, non-commercial entertainment. Do not cheat, tamper with saves or scores, or abuse online services.

2. Virtual items
Coins, gems and boosters have no real-world value and cannot be exchanged for money. Purchases of virtual items are final except where required by law or the app store's policy.

3. Online features
Leaderboards and cloud save depend on a network connection. Scores are validated by the server; invalid scores may be removed.

4. Changes and availability
We may change, suspend or discontinue features at any time.

5. Disclaimer
The game is provided "as is" without warranties of any kind, to the extent permitted by law.

6. Contact
See Support and Feedback in the app."""

func on_back() -> void:
	main.go("settings")

func build() -> void:
	begin_page("Terms and Conditions", false, "settings")
	add_text(TEXT, 24, "text", HORIZONTAL_ALIGNMENT_LEFT, false)
