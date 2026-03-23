async function updateVisitorCount() {
  try {
    const response = await fetch('https://cag1lcjp3l.execute-api.us-east-1.amazonaws.com/prod/count');
    const data = await response.json();
    document.getElementById('visitor-count').textContent = data.count.toLocaleString();
  } catch (err) {
    document.getElementById('visitor-count').textContent = '—';
  }
}
updateVisitorCount();