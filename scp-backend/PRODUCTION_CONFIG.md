# Production Configuration Guide

This guide provides step-by-step instructions for configuring the SCP Platform backend for production deployment.

## 1. Generate Production JWT Secret

**CRITICAL**: A strong JWT secret is required for production. Never use the default "change-me-in-production" value.

### Quick Method (Recommended)

```bash
cd scp-backend
./scripts/generate-jwt-secret.sh
```

This will:
- Generate a cryptographically secure 64-character hex string
- Display it for you to copy
- Optionally update your `.env.production` file

### Manual Method

```bash
# Generate secret
openssl rand -hex 32

# Example output: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2
```

### Store the Secret

Add to your production environment:

```bash
export JWT_SECRET='your-generated-secret-here'
```

Or add to your `.env.production` file:
```
JWT_SECRET=your-generated-secret-here
```

**⚠️ Security Notes:**
- Never commit the actual secret to version control
- Store it in your deployment platform's secrets manager
- Use different secrets for staging and production
- If compromised, regenerate immediately (all users will need to re-authenticate)

## 2. Configure Production Database with SSL

### Database Configuration

Set these environment variables in production:

```bash
# Production Database Settings
DB_HOST=your-production-db-host.example.com
DB_PORT=5432
DB_USER=scp_production_user
DB_PASSWORD=your-secure-database-password
DB_NAME=scp_platform_production
DB_SSLMODE=require
```

### SSL Mode Options

- `disable` - No SSL (development only, NEVER use in production)
- `require` - Require SSL but don't verify certificate (recommended minimum)
- `verify-ca` - Require SSL and verify CA certificate
- `verify-full` - Require SSL and verify full certificate chain (most secure)

### Recommended Production Settings

```env
DB_SSLMODE=require
```

For enhanced security with certificate verification:
```env
DB_SSLMODE=verify-full
# Also set DB_SSLCERT, DB_SSLKEY, DB_SSLROOTCERT if needed
```

### Database Connection Pooling

The backend uses SQLX which handles connection pooling automatically. For production:
- Ensure your database allows sufficient connections
- Monitor connection pool usage
- Configure max connections based on your database plan

## 3. Configure Production CORS Origins

CORS (Cross-Origin Resource Sharing) controls which domains can access your API.

### Development CORS

```env
CORS_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:8080
```

### Production CORS

**Only include your actual frontend domains:**

```env
# Example production CORS configuration
CORS_ORIGINS=https://supplier.scp-platform.com,https://consumer.scp-platform.com,https://api.scp-platform.com
```

### Multiple Environments

For staging:
```env
CORS_ORIGINS=https://staging-supplier.scp-platform.com,https://staging-api.scp-platform.com
```

### Security Best Practices

1. **Never use wildcards** (`*`) in production
2. **Include protocol** (`https://`) explicitly
3. **No localhost** in production configuration
4. **Exact domain matching** - include subdomains explicitly
5. **Separate staging and production** origins

### Example Production Configuration

```env
# Production CORS - Exact domains only
CORS_ORIGINS=https://supplier.scp-platform.com,https://api.scp-platform.com

# If you have multiple subdomains:
CORS_ORIGINS=https://supplier.scp-platform.com,https://www.supplier.scp-platform.com,https://api.scp-platform.com
```

## 4. Enhanced Logging Configuration

### Log Levels

Available log levels:
- `debug` - Detailed debugging information
- `info` - General informational messages (default)
- `warn` - Warning messages
- `error` - Error messages only

### Production Logging

Set in your environment:

```env
LOG_LEVEL=info
LOG_FILE=/var/log/scp-platform/app.log
LOG_FORMAT=json
```

### Log Rotation

For production, use log rotation (logrotate on Linux):

```bash
# /etc/logrotate.d/scp-platform
/var/log/scp-platform/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0640 app app
    sharedscripts
    postrotate
        # Reload application if needed
    endscript
}
```

### Structured Logging

The backend supports JSON format for structured logging, which works well with log aggregation services:
- CloudWatch (AWS)
- Google Cloud Logging
- Datadog
- Splunk
- ELK Stack

### Monitoring Integration

For production monitoring, consider:
- Health check endpoint: `GET /health`
- Metrics endpoint (if implemented): `GET /metrics`
- Application Performance Monitoring (APM) tools

## 5. File Storage Configuration

### Local Storage (Development)

```env
STORAGE_TYPE=local
```

### S3 Storage (Production Recommended)

```env
STORAGE_TYPE=s3
S3_BUCKET=scp-platform-uploads-production
AWS_REGION=us-east-1
```

Also configure AWS credentials:
```bash
export AWS_ACCESS_KEY_ID=your-access-key
export AWS_SECRET_ACCESS_KEY=your-secret-key
```

Or use IAM roles if running on AWS infrastructure.

## 6. Complete Production Environment File

Create `.env.production` with all settings:

```env
# Server
PORT=3000
ENV=production

# Database (with SSL)
DB_HOST=your-production-db-host.com
DB_PORT=5432
DB_USER=scp_production_user
DB_PASSWORD=your-secure-database-password
DB_NAME=scp_platform_production
DB_SSLMODE=require

# JWT (generated with script)
JWT_SECRET=your-generated-secret-from-openssl
JWT_ACCESS_EXPIRY=15
JWT_REFRESH_EXPIRY=7

# Redis
REDIS_HOST=your-production-redis-host.com
REDIS_PORT=6379
REDIS_PASSWORD=your-redis-password

# CORS (your actual domains only)
CORS_ORIGINS=https://supplier.scp-platform.com,https://api.scp-platform.com

# Storage (S3 in production)
STORAGE_TYPE=s3
S3_BUCKET=scp-platform-uploads
AWS_REGION=us-east-1

# Logging
LOG_LEVEL=info
LOG_FILE=/var/log/scp-platform/app.log
LOG_FORMAT=json
```

## 7. Pre-Deployment Checklist

- [ ] JWT secret generated and stored securely
- [ ] Database configured with SSL (`DB_SSLMODE=require`)
- [ ] Production database credentials set
- [ ] CORS origins configured (no localhost)
- [ ] Logging configured with proper log level
- [ ] File storage configured (S3 recommended)
- [ ] Redis configured (if using)
- [ ] Environment variables set in deployment platform
- [ ] Secrets stored in secure vault/secrets manager
- [ ] Health check endpoint tested
- [ ] Database migrations run on production database
- [ ] Backup strategy in place
- [ ] Monitoring and alerting configured

## 8. Deployment Platform Examples

### Docker Deployment

```bash
docker run -d \
  --name scp-backend \
  -p 3000:3000 \
  --env-file .env.production \
  scp-backend:latest
```

### Kubernetes

Use ConfigMaps and Secrets:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: scp-backend-secrets
type: Opaque
stringData:
  JWT_SECRET: "your-secret-here"
  DB_PASSWORD: "your-db-password"
```

### AWS ECS/Fargate

Store secrets in AWS Secrets Manager or Parameter Store.

### Heroku

```bash
heroku config:set JWT_SECRET=your-secret
heroku config:set DB_SSLMODE=require
```

## 9. Security Hardening

Additional production security measures:

1. **HTTPS Only**: Use reverse proxy (nginx/CloudFlare) for SSL termination
2. **Rate Limiting**: Implement rate limiting middleware
3. **Request Size Limits**: Configure max request body size
4. **Headers**: Set security headers (CSP, HSTS, etc.)
5. **Database**: Use strong passwords, limit user privileges
6. **Firewall**: Restrict database access to backend servers only
7. **Backup**: Regular automated database backups
8. **Updates**: Keep dependencies updated for security patches

## 10. Monitoring and Alerts

Set up monitoring for:
- API response times
- Error rates
- Database connection pool usage
- Memory and CPU usage
- Disk space (for logs)
- Health check endpoint availability

## Support

For issues or questions, refer to:
- [Backend README](README.md)
- [Main Project README](../README.md)

