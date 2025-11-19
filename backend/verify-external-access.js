/**
 * Verify PostgreSQL External Access Configuration
 * Run this to check if PostgreSQL is properly configured for external connections
 * 
 * Usage: node verify-external-access.js
 */

const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);

console.log('🔍 Verifying PostgreSQL External Access Setup...\n');

async function runCheck(name, command, successText, failText) {
  try {
    console.log(`Checking: ${name}...`);
    const { stdout, stderr } = await execAsync(command);
    
    if (stdout.trim()) {
      console.log(`✅ ${successText}`);
      if (stdout.trim().length < 200) {
        console.log(`   ${stdout.trim()}`);
      }
      return true;
    } else {
      console.log(`❌ ${failText}`);
      return false;
    }
  } catch (error) {
    console.log(`❌ ${failText}`);
    if (error.stderr) {
      console.log(`   Error: ${error.stderr.trim().substring(0, 100)}`);
    }
    return false;
  }
}

async function verifySetup() {
  console.log('═══════════════════════════════════════════════════════\n');
  
  // Check 1: PostgreSQL Service
  console.log('1️⃣  PostgreSQL Service Status');
  const serviceRunning = await runCheck(
    'PostgreSQL Service',
    'sc query postgresql-x64-16',
    'PostgreSQL service is running',
    'PostgreSQL service is NOT running - Start it first!'
  );
  console.log('');
  
  // Check 2: Port Listening
  console.log('2️⃣  Port 5432 Status');
  const portListening = await runCheck(
    'Port 5432',
    'netstat -an | findstr ":5432"',
    'Port 5432 is listening',
    'Port 5432 is NOT listening - Check postgresql.conf'
  );
  console.log('');
  
  // Check 3: Firewall Rule
  console.log('3️⃣  Windows Firewall Rule');
  const firewallRule = await runCheck(
    'Firewall Rule',
    'netsh advfirewall firewall show rule name="PostgreSQL Server"',
    'Firewall rule exists',
    'Firewall rule NOT found - Create inbound rule for port 5432'
  );
  console.log('');
  
  // Check 4: IP Address
  console.log('4️⃣  Your IP Address');
  try {
    const { stdout } = await execAsync('ipconfig | findstr "IPv4"');
    console.log('✅ Network IP addresses:');
    const lines = stdout.split('\n').filter(line => line.trim());
    lines.forEach(line => {
      const match = line.match(/(\d+\.\d+\.\d+\.\d+)/);
      if (match) {
        const ip = match[1];
        if (!ip.startsWith('127.')) {
          console.log(`   📍 ${ip} - Share this with collaborators!`);
        }
      }
    });
  } catch (error) {
    console.log('❌ Could not get IP address');
  }
  console.log('');
  
  // Summary
  console.log('═══════════════════════════════════════════════════════');
  console.log('\n📊 SUMMARY:\n');
  
  const checks = [
    { name: 'PostgreSQL Running', status: serviceRunning },
    { name: 'Port 5432 Open', status: portListening },
    { name: 'Firewall Rule', status: firewallRule },
  ];
  
  const passed = checks.filter(c => c.status).length;
  const total = checks.length;
  
  checks.forEach(check => {
    console.log(`   ${check.status ? '✅' : '❌'} ${check.name}`);
  });
  
  console.log('');
  
  if (passed === total) {
    console.log('🎉 ALL CHECKS PASSED!');
    console.log('✅ PostgreSQL is configured for external connections.');
    console.log('\n📋 Next Steps:');
    console.log('   1. Share your IP address with collaborators');
    console.log('   2. Ensure postgresql.conf has: listen_addresses = \'*\'');
    console.log('   3. Ensure pg_hba.conf allows network connections');
    console.log('   4. Tell collaborators to use: psql -h YOUR_IP -U flowspace_user -d flow_space');
  } else {
    console.log(`⚠️  ${total - passed} CHECK(S) FAILED`);
    console.log('\n🔧 To Fix:');
    if (!serviceRunning) {
      console.log('   • Start PostgreSQL service: services.msc');
    }
    if (!portListening) {
      console.log('   • Edit postgresql.conf: listen_addresses = \'*\'');
      console.log('   • Restart PostgreSQL service');
    }
    if (!firewallRule) {
      console.log('   • Run PowerShell as Admin:');
      console.log('     New-NetFirewallRule -DisplayName "PostgreSQL Server" -Direction Inbound -LocalPort 5432 -Protocol TCP -Action Allow');
    }
    console.log('\n📖 See: backend/POSTGRESQL_EXTERNAL_SETUP.md for detailed guide');
  }
  
  console.log('\n═══════════════════════════════════════════════════════\n');
}

verifySetup().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});

