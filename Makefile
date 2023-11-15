setup:
	curl https://sh.rustup.rs -sSf | sh -s -- -y
	cargo install aftman
	aftman self-install
	aftman install --no-trust-check
	wally install
