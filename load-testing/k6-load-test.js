import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
export let errorRate = new Rate('errors');

// Test configuration
export let options = {
  stages: [
    { duration: '30s', target: 10 },   // Warm up
    { duration: '1m', target: 50 },     // Ramp up to normal traffic
    { duration: '2m', target: 100 },    // Traffic spike simulation (12:00 PM scenario)
    { duration: '1m', target: 200 },     // Peak traffic
    { duration: '1m', target: 50 },      // Scale down
    { duration: '30s', target: 0 },     // Cool down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],  // 95% of requests under 500ms
    http_req_failed: ['rate<0.1'],      // Error rate under 10%
    errors: ['rate<0.1'],               // Custom error rate under 10%
  },
};

// Defaults are for local port-forward. Override for EKS:
// BASE_URL="http://<LB_DNS>" API_BASE_URL="http://<LB_DNS>" k6 run load-testing/k6-load-test.js
const BASE_URL = __ENV.BASE_URL || 'http://a7364d6ed395543bf8ce027d4068b13c-0fa29ec62ffaa978.elb.ap-south-1.amazonaws.com/';
const API_BASE_URL = __ENV.API_BASE_URL || BASE_URL;

export function setup() {
  // Test data setup - create a test URL
  let payload = {
    long_url: 'https://github.com/xaadu/urlshortner-microservices',
  };
  
  let params = {
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
  };
  
  let response = http.post(`${API_BASE_URL}/create`, `long_url=${payload.long_url}`, params);
  check(response, {
    'test URL created successfully': (r) => r.status === 200,
  });
  
  return response.json();
}

export default function(data) {
  // Test 1: Create short URL (30% of traffic)
  if (Math.random() < 0.3) {
    let payload = {
      long_url: `https://example.com/${Math.random().toString(36).substring(7)}`,
    };
    
    let params = {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    };
    
    let response = http.post(`${API_BASE_URL}/create`, `long_url=${payload.long_url}`, params);
    
    let success = check(response, {
      'create status is 200': (r) => r.status === 200,
      'create response time < 500ms': (r) => r.timings.duration < 500,
    });
    
    errorRate.add(!success);
  }
  
  // Test 2: Access dashboard (40% of traffic)
  if (Math.random() < 0.4) {
    let response = http.get(`${BASE_URL}/`);
    
    let success = check(response, {
      'dashboard status is 200': (r) => r.status === 200,
      'dashboard response time < 300ms': (r) => r.timings.duration < 300,
    });
    
    errorRate.add(!success);
  }
  
  // Test 3: Get statistics (20% of traffic)
  if (Math.random() < 0.2) {
    let response = http.get(`${API_BASE_URL}/api/stats`);
    
    let success = check(response, {
      'stats status is 200': (r) => r.status === 200,
      'stats response time < 200ms': (r) => r.timings.duration < 200,
      'stats has required fields': (r) => {
        try {
          let json = JSON.parse(r.body);
          return json.hasOwnProperty('total_urls') && json.hasOwnProperty('total_clicks');
        } catch (e) {
          return false;
        }
      },
    });
    
    errorRate.add(!success);
  }
  
  // Test 4: Test redirect (10% of traffic)
  if (Math.random() < 0.1 && data && data.short_code) {
    // Note: This would test the redirect service directly
    // In a real scenario, you'd test the redirect endpoint
    let response = http.get(`http://localhost:8000/${data.short_code}`, {
      redirects: 0,  // Don't follow redirects to test the redirect response
    });
    
    let success = check(response, {
      'redirect status is 302': (r) => r.status === 302,
      'redirect response time < 100ms': (r) => r.timings.duration < 100,
    });
    
    errorRate.add(!success);
  }
  
  sleep(1);
}

export function teardown(data) {
  console.log('Load test completed');
  console.log(`Test data: ${JSON.stringify(data)}`);
}
