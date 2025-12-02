# Scheduling Jobs with Docker

Since you're using Docker, the standard `whenever --update-crontab` won't work because Docker containers don't have cron installed by default. Here are your options:

## Recommended Options for Docker

### Option 1: Host-Level Cron (Simplest & Recommended)

Run cron jobs from your **host machine** (not inside Docker). This is the cleanest approach.

**Setup:**

1. On your host machine, edit crontab:
   ```bash
   crontab -e
   ```

2. Add this line:
   ```bash
   # Sync shop data daily at 2 AM
   0 2 * * * cd /path/to/cheddah-rails && docker-compose exec -T web bundle exec rake shop:sync_all RAILS_ENV=production >> log/cron.log 2>&1
   ```

3. Save and verify:
   ```bash
   crontab -l
   ```

**Advantages:**
- ✅ Simple - no changes to Docker setup
- ✅ Reliable - cron is managed by the host OS
- ✅ Easy to debug - logs on host system
- ✅ No container restarts needed

**Test it manually:**
```bash
cd /path/to/cheddah-rails
docker-compose exec -T web bundle exec rake shop:sync_all RAILS_ENV=development
```

### Option 2: Install Cron in Docker Container

Add cron to your Docker container and run it alongside your Rails app.

**1. Update your Dockerfile:**

Add after the base image:
```dockerfile
# Install cron
RUN apt-get update && apt-get install -y cron && rm -rf /var/lib/apt/lists/*

# Copy application files first
COPY . .

# Install gems
RUN bundle install

# Write crontab using whenever
RUN bundle exec whenever --update-crontab --set environment=production
```

**2. Update your entrypoint script:**

Create or modify `docker-entrypoint.sh`:
```bash
#!/bin/bash
set -e

# Start cron in background
service cron start

# Start Rails
exec "$@"
```

**3. Update Dockerfile to use entrypoint:**
```dockerfile
COPY docker-entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

**4. Rebuild and restart:**
```bash
docker-compose build
docker-compose up -d
```

**Verify cron is running:**
```bash
docker-compose exec web service cron status
docker-compose exec web crontab -l
```

**Disadvantages:**
- ❌ More complex Docker setup
- ❌ Cron may not restart properly if container crashes
- ❌ Adds overhead to container

### Option 3: Docker Compose with Separate Scheduler Service

Run a separate container just for scheduled tasks.

**Update docker-compose.yml:**
```yaml
services:
  web:
    # Your existing web service
    build: .
    ports:
      - "3000:3000"
    # ... other config

  scheduler:
    build: .
    command: bash -c "apt-get update && apt-get install -y cron && bundle exec whenever --update-crontab && cron && tail -f /dev/null"
    depends_on:
      - web
      - db
    environment:
      - RAILS_ENV=production
    volumes:
      - .:/app
```

**Start services:**
```bash
docker-compose up -d
```

**Advantages:**
- ✅ Separates concerns
- ✅ Can restart scheduler independently

**Disadvantages:**
- ❌ Uses extra container resources
- ❌ More complex docker-compose setup

### Option 4: External Cron Service (Production)

For production, use a dedicated cron service:

**For AWS:**
- Use **Amazon EventBridge** (formerly CloudWatch Events)
- Trigger HTTP endpoint or run ECS task

**For DigitalOcean:**
- Use their **App Platform Cron Jobs**

**For Kubernetes:**
- Use **CronJobs** resource:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: shop-sync
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: shop-sync
            image: your-image
            command: ["bundle", "exec", "rake", "shop:sync_all"]
          restartPolicy: OnFailure
```

## Testing Your Setup

### Test the Rake Task

```bash
# In Docker
docker-compose exec web bundle exec rake shop:sync_all

# Should see output about shops being synced
```

### Test with Docker Exec (Host Cron)

```bash
# This is what your host cron will run
cd /path/to/cheddah-rails
docker-compose exec -T web bundle exec rake shop:sync_all RAILS_ENV=development
```

### Check Logs

```bash
# Production logs
docker-compose exec web tail -f log/production.log

# Cron logs (if using Option 1 - host cron)
tail -f log/cron.log

# Cron logs (if using Option 2 - cron in container)
docker-compose exec web tail -f log/cron.log
```

## Recommended Setup for Your Project

Based on your Docker setup, I recommend **Option 1: Host-Level Cron**:

### Quick Setup

1. **On your development machine:**
   ```bash
   crontab -e
   ```

2. **Add this line** (adjust path to your project):
   ```bash
   # Cheddah Rails - Sync shop data daily at 2 AM
   0 2 * * * cd /Users/jaychinthrajah/workspaces/_personal_/cheddah/cheddah-rails && docker-compose exec -T web bundle exec rake shop:sync_all RAILS_ENV=development >> log/cron.log 2>&1
   ```

3. **For production server**, use the same approach but with `RAILS_ENV=production`

4. **Verify:**
   ```bash
   crontab -l
   ```

### Why This Works Best

- ✅ No Docker changes needed
- ✅ Works with your existing `config/schedule.rb` (for documentation)
- ✅ Easy to debug and monitor
- ✅ Cron runs even if container restarts
- ✅ Can manually trigger anytime with the same command

## Preview Your Schedule

Even though you can't use `whenever --update-crontab` in Docker, you can still preview what the cron schedule would be:

```bash
docker-compose exec web bundle exec whenever
```

This shows you the cron syntax, which you can then adapt for host-level cron or other scheduling systems.

## Alternative: Run Jobs Manually

For development, you might not need automated scheduling. Just run manually when needed:

```bash
docker-compose exec web bundle exec rake shop:sync_all
```

Or add a Makefile target:

```makefile
sync-shops:
	docker-compose exec web bundle exec rake shop:sync_all
```

Then run:
```bash
make sync-shops
```

## Monitoring

### Add Logging to Your Cron Command

```bash
# Detailed logging
0 2 * * * cd /path/to/app && docker-compose exec -T web bundle exec rake shop:sync_all RAILS_ENV=production >> log/cron.log 2>&1

# Email on failure (requires mail configured on host)
0 2 * * * cd /path/to/app && docker-compose exec -T web bundle exec rake shop:sync_all RAILS_ENV=production || echo "Shop sync failed" | mail -s "Cron Failure" you@example.com
```

### Check if Jobs Ran

```bash
# View cron log
tail -f log/cron.log

# View production log
docker-compose exec web tail -f log/production.log | grep SyncShopData

# Check database for recent updates
docker-compose exec web bundle exec rails runner "puts Shop.first.updated_at"
```

## Summary

For your Docker setup:

1. ✅ **Development**: Use host-level cron with the command above
2. ✅ **Production**: Same approach, or use cloud provider's cron service
3. ✅ Keep `config/schedule.rb` for documentation and `whenever` preview
4. ✅ Test manually first: `docker-compose exec web bundle exec rake shop:sync_all`

The Whenever gem is still useful for documenting your schedule in a readable format, even if you can't use `--update-crontab` directly in Docker!
