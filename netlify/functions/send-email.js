// Netlify Function — sends email with PDF attachment via Resend
exports.handler = async (event) => {
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method not allowed' };
  }

  const RESEND_API_KEY = process.env.RESEND_API_KEY;
  if (!RESEND_API_KEY) {
    return { statusCode: 500, body: JSON.stringify({ error: 'RESEND_API_KEY not configured' }) };
  }

  let body;
  try {
    body = JSON.parse(event.body);
  } catch (e) {
    return { statusCode: 400, body: JSON.stringify({ error: 'Invalid JSON' }) };
  }

  const { to, subject, message, from_name, pdf_base64, pdf_filename } = body;

  if (!to || !subject || !message) {
    return { statusCode: 400, body: JSON.stringify({ error: 'Missing required fields: to, subject, message' }) };
  }

  // Build attachments array if PDF provided
  const attachments = [];
  if (pdf_base64 && pdf_filename) {
    // Strip data URI prefix if present
    const base64Data = pdf_base64.replace(/^data:[^;]+;base64,/, '');
    attachments.push({
      filename: pdf_filename,
      content: base64Data,
      content_type: 'application/pdf'
    });
  }

  // Split recipients and send
  const recipients = to.split(',').map(e => e.trim()).filter(Boolean);

  const emailPayload = {
    from: from_name ? `${from_name} <onboarding@resend.dev>` : 'ElectricalPM <onboarding@resend.dev>',
    to: recipients,
    subject: subject,
    text: message,
  };

  if (attachments.length > 0) {
    emailPayload.attachments = attachments;
  }

  try {
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(emailPayload),
    });

    const data = await res.json();

    if (!res.ok) {
      console.error('Resend error:', data);
      return { statusCode: res.status, body: JSON.stringify({ error: data.message || 'Email send failed' }) };
    }

    return { statusCode: 200, body: JSON.stringify({ success: true, id: data.id }) };
  } catch (err) {
    console.error('Send error:', err);
    return { statusCode: 500, body: JSON.stringify({ error: 'Failed to send email' }) };
  }
};
