# Monitoring and Logging Setup Guide

This guide covers setting up monitoring and logging for the SCP Platform in production.

## Overview

The SCP Platform includes:
- **Enhanced Logging**: Structured JSON logging with file output support
- **Health Check Endpoint**: Built-in health monitoring
- **Error Tracking**: Comprehensive error logging
- **Performance Monitoring**: Request latency tracking

## 1. Logging Configuration

### Basic Logging Setup

The backend supports both text and JSON log formats with optional file output.

#### Environment Variables

```env
# Log format: text or json
LOG_FORMAT=json

# Optional: Write logs to file
LOG_FILE=/var/log/scp-platform/app.log

# Log level is controlled by environment
ENV=production  # Automatically uses info level
```

### Log Formats

#### Text Format (Default)
```
127.0.0.1 - [2024-12-15T10:30:45Z] "GET /api/v1/auth/me HTTP/1.1 200 2.5ms "Mozilla/5.0..." "
```

#### JSON Format (Production Recommended)
```json
{"timestamp":"2024-12-15T10:30:45Z","level":"info","method":"GET","path":"/api/v1/auth/me","status":200,"latency":"2.5ms","client_ip":"127.0.0.1","user_agent":"Mozilla/5.0..."}
```

### Log Levels

Log levels are automatically determined by HTTP status codes:
- **info**: Status 200-399 (successful requests)
- **warn**: Status 400-499 (client errors)
- **error**: Status 500+ (server errors)

### File Logging Setup

#### Create Log Directory

```bash
sudo mkdir -p /var/log/scp-platform
sudo chown your-user:your-group /var/log/scp-platform
```

#### Configure Log Rotation

Create `/etc/logrotate.d/scp-platform`:

```bash
/var/log/scp-platform/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0640 your-user your-group
    sharedscripts
    postrotate
        # Reload application if it reads log file handle
        # systemctl reload scp-backend || true
    endscript
}
```

Test log rotation:
```bash
sudo logrotate -d /etc/logrotate.d/scp-platform
```

## 2. Health Check Monitoring

### Health Check Endpoint

The backend provides a health check endpoint:

```bash
curl http://localhost:3000/health
```

Response:
```json
{"status":"ok"}
```

### Monitoring Setup

#### Simple HTTP Check

```bash
#!/bin/bash
# health-check.sh
HEALTH_URL="http://localhost:3000/health"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_URL)

if [ "$RESPONSE" != "200" ]; then
    echo "Health check failed: $RESPONSE"
    exit 1
fi
```

#### Systemd Service with Health Check

Add to your systemd service file:

```ini
[Unit]
Description=SCP Platform Backend
After=network.target

[Service]
Type=simple
User=your-user
WorkingDirectory=/opt/scp-platform/scp-backend
ExecStart=/opt/scp-platform/scp-backend/main
Restart=always
RestartSec=5
EnvironmentFile=/etc/scp-platform/.env

# Health check
ExecStartPost=/bin/bash -c 'sleep 2 && curl -f http://localhost:3000/health || exit 1'

[Install]
WantedBy=multi-user.target
```

## 3. Log Aggregation Services

### CloudWatch (AWS)

1. **Install CloudWatch Agent** (if on EC2)
2. **Configure log group**: `/aws/ec2/scp-platform/application`
3. **Set up IAM permissions** for log streaming

#### CloudWatch Configuration

```json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/scp-platform/app.log",
            "log_group_name": "/aws/ec2/scp-platform/application",
            "log_stream_name": "{instance_id}",
            "timestamp_format": "%Y-%m-%d %H:%M:%S"
          }
        ]
      }
    }
  }
}
```

### Datadog

1. **Install Datadog Agent**
2. **Configure log collection**:

```yaml
# /etc/datadog-agent/datadog.yaml
logs_enabled: true
```

```yaml
# /etc/datadog-agent/conf.d/go.d/conf.yaml
logs:
  - type: file
    path: /var/log/scp-platform/app.log
    service: scp-platform
    source: go
    sourcecategory: application
```

### Google Cloud Logging

If running on GCP:

```bash
# Use Cloud Logging API
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
```

Logs are automatically collected if running on Compute Engine or GKE.

### ELK Stack (Elasticsearch, Logstash, Kibana)

1. **Configure Logstash** to read log files:

```ruby
# logstash.conf
input {
  file {
    path => "/var/log/scp-platform/app.log"
    codec => json
    start_position => "beginning"
  }
}

output {
  elasticsearch {
    hosts => ["localhost:9200"]
    index => "scp-platform-%{+YYYY.MM.dd}"
  }
}
```

## 4. Application Performance Monitoring (APM)

### Key Metrics to Monitor

1. **Response Times**
   - Average response time
   - P95/P99 percentiles
   - Slowest endpoints

2. **Error Rates**
   - 4xx errors (client errors)
   - 5xx errors (server errors)
   - Error rate percentage

3. **Request Volume**
   - Requests per second
   - Peak load times
   - Traffic patterns

4. **Database Metrics**
   - Connection pool usage
   - Query performance
   - Slow queries

5. **System Resources**
   - CPU usage
   - Memory usage
   - Disk I/O

### APM Tools

#### New Relic

1. Install New Relic agent for Go
2. Configure application name
3. Set up alerts for error rates and response times

#### Datadog APM

1. Enable APM in Datadog
2. Install Datadog agent with APM enabled
3. Configure service tagging

#### Prometheus + Grafana

Set up metrics endpoint and scrape with Prometheus:

```go
// Example: Add to routes.go
router.GET("/metrics", func(c *gin.Context) {
    // Expose Prometheus metrics
})
```

## 5. Alerting Configuration

### Critical Alerts

Set up alerts for:

1. **Health Check Failures**
   - Endpoint returns non-200
   - Endpoint timeout

2. **High Error Rate**
   - > 5% 5xx errors in 5 minutes
   - > 10% 4xx errors in 5 minutes

3. **High Response Time**
   - P95 > 2 seconds
   - P99 > 5 seconds

4. **Database Issues**
   - Connection pool exhaustion
   - Database downtime

5. **System Resources**
   - CPU > 80% for 5 minutes
   - Memory > 90%
   - Disk space < 10%

### Alert Examples

#### CloudWatch Alarms

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name scp-platform-high-error-rate \
  --alarm-description "Alert when error rate exceeds 5%" \
  --metric-name ErrorRate \
  --namespace SCPPlatform \
  --statistic Average \
  --period 300 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1
```

#### PagerDuty Integration

1. Create PagerDuty service
2. Configure webhook for alerts
3. Set up escalation policies

## 6. Log Analysis Best Practices

### Structured Logging Benefits

With JSON logging, you can easily query logs:

```bash
# Find all errors
jq 'select(.level == "error")' /var/log/scp-platform/app.log

# Find slow requests (> 1 second)
jq 'select(.latency | test("^[1-9]"))' /var/log/scp-platform/app.log

# Count requests by endpoint
jq -r '.path' /var/log/scp-platform/app.log | sort | uniq -c
```

### Log Retention

- **Development**: 7 days
- **Staging**: 30 days
- **Production**: 90 days (or as required by compliance)

### Log Security

1. **Sanitize sensitive data** before logging
2. **Never log passwords** or tokens
3. **Rotate logs** regularly
4. **Encrypt log files** at rest if containing sensitive data
5. **Limit access** to log files

## 7. Monitoring Dashboard

### Create Monitoring Dashboard

Set up a dashboard showing:

1. **Request Metrics**
   - Requests per second
   - Success/error rates
   - Average response time

2. **Error Breakdown**
   - Errors by status code
   - Errors by endpoint
   - Error trends over time

3. **System Health**
   - CPU and memory usage
   - Database connections
   - Active WebSocket connections

4. **Business Metrics**
   - Orders per hour
   - Active users
   - API usage by endpoint

### Grafana Dashboard Example

Import Grafana dashboard JSON with panels for:
- Request rate graph
- Error rate graph
- Response time graph
- System metrics
- Database metrics

## 8. Production Checklist

- [ ] Log format configured (JSON recommended)
- [ ] Log file path configured and directory created
- [ ] Log rotation configured
- [ ] Health check endpoint tested
- [ ] Monitoring service configured (CloudWatch/Datadog/etc.)
- [ ] Alerts configured for critical issues
- [ ] Dashboard created with key metrics
- [ ] Log retention policy set
- [ ] Access controls for logs configured
- [ ] Backup of log configuration

## 9. Troubleshooting

### Logs Not Appearing

1. Check file permissions
2. Verify LOG_FILE path exists
3. Check disk space
4. Verify application has write permissions

### High Log Volume

1. Adjust log level
2. Filter out verbose endpoints
3. Use log sampling for high-traffic endpoints
4. Consider log aggregation service

### Performance Impact

1. Use async log writing
2. Buffer logs before writing
3. Use log aggregation service instead of file logging
4. Monitor disk I/O

## Support

For more information:
- [Production Configuration Guide](scp-backend/PRODUCTION_CONFIG.md)
- [Backend README](scp-backend/README.md)

