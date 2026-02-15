// Run: node generate-cards.js
// Generates 312x390 city card PNGs using canvas

const { createCanvas } = require('canvas');
const fs = require('fs');
const path = require('path');

const cities = [
  { name: 'Tokyo', emoji: '🗼', subtitle: '🇯🇵 Japan', gradient: ['#ff6b8a', '#c44569', '#6c2142'] },
  { name: 'Paris', emoji: '🗼', subtitle: '🇫🇷 France', gradient: ['#667eea', '#764ba2', '#3a1c71'] },
  { name: 'NewYork', emoji: '🗽', subtitle: '🇺🇸 USA', gradient: ['#f093fb', '#f5576c', '#c62828'] },
  { name: 'London', emoji: '🏰', subtitle: '🇬🇧 United Kingdom', gradient: ['#4facfe', '#00f2fe', '#0052d4'] },
];

const W = 312, H = 390;

for (const city of cities) {
  const canvas = createCanvas(W, H);
  const ctx = canvas.getContext('2d');

  // Rounded rect clip
  const r = 40;
  ctx.beginPath();
  ctx.moveTo(r, 0); ctx.lineTo(W-r, 0); ctx.quadraticCurveTo(W, 0, W, r);
  ctx.lineTo(W, H-r); ctx.quadraticCurveTo(W, H, W-r, H);
  ctx.lineTo(r, H); ctx.quadraticCurveTo(0, H, 0, H-r);
  ctx.lineTo(0, r); ctx.quadraticCurveTo(0, 0, r, 0);
  ctx.closePath(); ctx.clip();

  // Gradient
  const grad = ctx.createLinearGradient(0, 0, W*0.6, H);
  grad.addColorStop(0, city.gradient[0]);
  grad.addColorStop(0.5, city.gradient[1]);
  grad.addColorStop(1, city.gradient[2]);
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, W, H);

  // City name
  ctx.fillStyle = 'white';
  ctx.font = 'bold 36px sans-serif';
  ctx.textAlign = 'center';
  ctx.fillText(city.name, W/2, H/2 + 50);

  // Subtitle
  ctx.font = '16px sans-serif';
  ctx.fillStyle = 'rgba(255,255,255,0.7)';
  ctx.fillText(city.subtitle, W/2, H/2 + 76);

  // Border
  ctx.strokeStyle = 'rgba(255,255,255,0.15)';
  ctx.lineWidth = 3;
  ctx.beginPath();
  ctx.moveTo(r, 0); ctx.lineTo(W-r, 0); ctx.quadraticCurveTo(W, 0, W, r);
  ctx.lineTo(W, H-r); ctx.quadraticCurveTo(W, H, W-r, H);
  ctx.lineTo(r, H); ctx.quadraticCurveTo(0, H, 0, H-r);
  ctx.lineTo(0, r); ctx.quadraticCurveTo(0, 0, r, 0);
  ctx.closePath(); ctx.stroke();

  // Save
  const outDir = path.join(__dirname, 'watch_cards');
  fs.writeFileSync(path.join(outDir, `${city.name}.png`), canvas.toBuffer('image/png'));
  console.log(`✅ ${city.name}.png`);
}
console.log('Done! Cards in demo_videos/watch_cards/');
