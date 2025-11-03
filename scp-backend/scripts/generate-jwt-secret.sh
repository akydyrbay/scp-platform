#!/bin/bash

# Generate JWT Secret for Production
# This script generates a cryptographically secure random secret for JWT token signing

echo "🔐 Generating JWT Secret for Production"
echo "======================================="
echo ""

# Check if openssl is available
if ! command -v openssl &> /dev/null; then
    echo "❌ Error: openssl is not installed"
    echo "   Please install openssl or use an alternative method"
    exit 1
fi

# Generate 64-character hex string (32 bytes)
SECRET=$(openssl rand -hex 32)

echo "✅ Generated JWT Secret:"
echo ""
echo "$SECRET"
echo ""
echo "📋 Next Steps:"
echo "  1. Copy the secret above"
echo "  2. Add it to your production environment:"
echo "     export JWT_SECRET='$SECRET'"
echo "  3. Add to your .env.production file:"
echo "     JWT_SECRET=$SECRET"
echo "  4. Store it securely in your deployment platform's secrets manager"
echo ""
echo "⚠️  IMPORTANT:"
echo "  - Keep this secret secure and private"
echo "  - Never commit it to version control"
echo "  - If compromised, generate a new one immediately"
echo "  - All users will need to re-authenticate if you change this"
echo ""

# Optionally save to a secure file
read -p "Save to .env.production? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f ".env.production" ]; then
        # Update existing JWT_SECRET in .env.production
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s/^JWT_SECRET=.*/JWT_SECRET=$SECRET/" .env.production
        else
            # Linux
            sed -i "s/^JWT_SECRET=.*/JWT_SECRET=$SECRET/" .env.production
        fi
        echo "✅ Updated .env.production"
    else
        echo "❌ .env.production file not found"
        echo "   Create it first from .env.production.example"
    fi
fi

