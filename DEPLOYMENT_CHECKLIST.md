# Production Deployment Checklist

Complete checklist for deploying the SCP Platform to production.

## Pre-Deployment

### 1. JWT Secret Generation ✅

- [ ] Run `./scp-backend/scripts/generate-jwt-secret.sh`
- [ ] Copy generated secret securely
- [ ] Add to production environment variables
- [ ] Store in secrets manager (AWS Secrets Manager, HashiCorp Vault, etc.)
- [ ] Verify secret is NOT in version control

**Command:**
```bash
cd scp-backend
./scripts/generate-jwt-secret.sh
```

### 2. Database Configuration ✅

- [ ] Production database created
- [ ] Database user created with minimal required permissions
- [ ] Strong password set (not default)
- [ ] SSL mode configured (`DB_SSLMODE=require`)
- [ ] Database migrations run
- [ ] Connection pool limits configured
- [ ] Backup strategy configured
- [ ] Point-in-time recovery enabled (if available)

**Environment Variables:**
```env
DB_HOST=your-production-db-host.com
DB_PORT=5432
DB_USER=scp_production_user
DB_PASSWORD=your-secure-password
DB_NAME=scp_platform_production
DB_SSLMODE=require
```

### 3. CORS Origins Configuration ✅

- [ ] Production domains identified
- [ ] CORS_ORIGINS set to production domains only
- [ ] No localhost entries in production
- [ ] HTTPS enforced
- [ ] Wildcards removed

**Environment Variable:**
```env
CORS_ORIGINS=https://supplier.scp-platform.com,https://api.scp-platform.com
```

### 4. Mobile App Signing ✅

#### Android
- [ ] Consumer app keystore created
- [ ] Supplier app keystore created
- [ ] Keystores backed up securely (critical!)
- [ ] key.properties configured locally
- [ ] GitHub Secrets configured (for CI/CD):
  - `CONSUMER_KEYSTORE_BASE64`
  - `CONSUMER_KEYSTORE_PASSWORD`
  - `CONSUMER_KEY_PASSWORD`
  - `SUPPLIER_KEYSTORE_BASE64`
  - `SUPPLIER_KEYSTORE_PASSWORD`
  - `SUPPLIER_KEY_PASSWORD`
- [ ] Release builds tested locally

**Setup Script:**
```bash
./scripts/setup-android-signing.sh
```

#### iOS
- [ ] Apple Developer account configured
- [ ] Bundle IDs registered:
  - `com.scp.consumer`
  - `com.scp.supplier`
- [ ] Provisioning profiles created
- [ ] Code signing configured in Xcode
- [ ] Certificates stored securely

### 5. Monitoring and Logging ✅

- [ ] Log format configured (JSON recommended)
- [ ] Log file path configured
- [ ] Log rotation configured
- [ ] Log aggregation service set up (CloudWatch/Datadog/etc.)
- [ ] Health check endpoint tested (`/health`)
- [ ] Alerts configured for:
  - Health check failures
  - High error rates
  - High response times
  - System resource issues
- [ ] Dashboard created with key metrics

**See:** [MONITORING_SETUP.md](MONITORING_SETUP.md)

## Environment Configuration

### Backend Environment Variables

Create `.env.production` with:

```env
# Server
PORT=3000
ENV=production

# Database (SSL required)
DB_HOST=your-production-db-host.com
DB_PORT=5432
DB_USER=scp_production_user
DB_PASSWORD=your-secure-password
DB_NAME=scp_platform_production
DB_SSLMODE=require

# JWT (generated secret)
JWT_SECRET=your-generated-secret-from-script
JWT_ACCESS_EXPIRY=15
JWT_REFRESH_EXPIRY=7

# Redis
REDIS_HOST=your-production-redis-host.com
REDIS_PORT=6379
REDIS_PASSWORD=your-redis-password

# CORS (production domains only)
CORS_ORIGINS=https://supplier.scp-platform.com,https://api.scp-platform.com

# Storage (S3 in production)
STORAGE_TYPE=s3
S3_BUCKET=scp-platform-uploads-production
AWS_REGION=us-east-1

# Logging
LOG_LEVEL=info
LOG_FILE=/var/log/scp-platform/app.log
LOG_FORMAT=json
```

### Frontend Environment Variables

#### Next.js Web Portal
```env
NEXT_PUBLIC_API_BASE_URL=https://api.scp-platform.com/api/v1
```

#### Flutter Mobile Apps
- Use `ENV=production` build flag
- API URL automatically set to: `https://api.scp-platform.com/api/v1`

## Security Hardening

### Backend Security
- [ ] HTTPS enforced (reverse proxy)
- [ ] Security headers configured (HSTS, CSP, etc.)
- [ ] Rate limiting configured
- [ ] Request size limits set
- [ ] Database firewall rules configured
- [ ] SSH key-only access (no passwords)
- [ ] Regular security updates scheduled
- [ ] Dependencies updated (security patches)

### Secrets Management
- [ ] All secrets in secrets manager
- [ ] No secrets in code or config files
- [ ] Secrets rotation policy defined
- [ ] Access audit logging enabled

## Infrastructure Setup

### Server Requirements
- [ ] Production server provisioned
- [ ] Firewall rules configured
- [ ] SSL certificate installed
- [ ] Reverse proxy configured (nginx/CloudFlare)
- [ ] Load balancer configured (if needed)
- [ ] Auto-scaling configured (if needed)

### Database
- [ ] Production database instance created
- [ ] Automated backups enabled
- [ ] Point-in-time recovery configured
- [ ] Connection limits set appropriately
- [ ] Monitoring enabled

### File Storage
- [ ] S3 bucket created (or equivalent)
- [ ] Bucket policy configured
- [ ] CORS configured on bucket
- [ ] Lifecycle policies set (archival/deletion)

## Testing

### Pre-Production Testing
- [ ] All unit tests passing
- [ ] Integration tests passing
- [ ] Load testing completed
- [ ] Security testing performed
- [ ] End-to-end testing completed
- [ ] Performance benchmarks met

### Production Verification
- [ ] Health check returns 200
- [ ] Authentication flow works
- [ ] API endpoints responding correctly
- [ ] Database connections stable
- [ ] Logs appearing correctly
- [ ] Monitoring dashboards populated
- [ ] Alerts configured and tested

## Documentation

- [ ] Production configuration documented
- [ ] Deployment procedure documented
- [ ] Rollback procedure documented
- [ ] Incident response plan created
- [ ] On-call rotation established
- [ ] Team access granted

## Deployment

### Backend Deployment
1. [ ] Build Docker image (or binary)
2. [ ] Tag with version number
3. [ ] Push to container registry
4. [ ] Deploy to production
5. [ ] Run database migrations
6. [ ] Verify health check
7. [ ] Monitor logs for errors

### Frontend Deployment

#### Web Portal
1. [ ] Build production bundle
2. [ ] Deploy to hosting platform
3. [ ] Set environment variables
4. [ ] Verify site loads
5. [ ] Test authentication
6. [ ] Test key features

#### Mobile Apps
1. [ ] Build release APK/IPA
2. [ ] Sign with production certificates
3. [ ] Upload to app stores
4. [ ] Submit for review
5. [ ] Test on physical devices
6. [ ] Monitor crash reports

## Post-Deployment

### Immediate Checks
- [ ] Health check endpoint responding
- [ ] All services running
- [ ] No error spikes in logs
- [ ] Response times normal
- [ ] Database connections stable
- [ ] Monitoring dashboards working

### First 24 Hours
- [ ] Monitor error rates
- [ ] Watch resource usage
- [ ] Check user feedback
- [ ] Review application logs
- [ ] Verify backup processes
- [ ] Confirm alert notifications

### First Week
- [ ] Performance review
- [ ] User feedback analysis
- [ ] Cost analysis
- [ ] Security review
- [ ] Optimization opportunities identified

## Rollback Plan

### Backend Rollback
- [ ] Previous version image tagged
- [ ] Rollback procedure documented
- [ ] Database rollback strategy (if needed)
- [ ] Rollback tested in staging

### Frontend Rollback
- [ ] Previous version available
- [ ] App store rollback procedure
- [ ] Web portal rollback procedure

## Support and Maintenance

- [ ] On-call schedule established
- [ ] Escalation path defined
- [ ] Documentation accessible to team
- [ ] Regular backup verification
- [ ] Security patch schedule
- [ ] Performance review schedule

## Resources

- [Production Configuration Guide](scp-backend/PRODUCTION_CONFIG.md)
- [Monitoring Setup Guide](MONITORING_SETUP.md)
- [Android Signing Setup](ANDROID_SIGNING_SETUP.md)
- [Backend README](scp-backend/README.md)

---

**Status**: Ready for Production Deployment ✅

Complete all checklist items before deploying to production.

