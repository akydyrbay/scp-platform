# Keystore Directory

Place your production keystore files here.

**IMPORTANT:**
- Never commit keystore files to version control
- Store keystore files securely
- Use different keystores for different environments if needed

## Creating a Keystore

```bash
keytool -genkey -v -keystore consumer-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias scp_consumer_key
```

Replace with your actual values and store passwords securely.

