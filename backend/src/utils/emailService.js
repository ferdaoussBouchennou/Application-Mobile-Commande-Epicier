const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: parseInt(process.env.SMTP_PORT || '587'),
  secure: false, // true for 465, false for 587
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

/**
 * Generate a random 6-digit OTP code
 */
const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

/**
 * Send an OTP code to a user email
 * @param {string} email
 * @param {string} code
 * @param {'verify'|'reset'} type
 */
const sendOTP = async (email, code, type = 'verify') => {
  const isVerify = type === 'verify';
  const subject = isVerify ? 'MyHanut – Vérification de votre email' : 'MyHanut – Réinitialisation de mot de passe';
  const actionLabel = isVerify ? 'vérifier votre compte' : 'réinitialiser votre mot de passe';

  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto;">
      <div style="background-color: #2D5016; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
        <h1 style="color: white; margin: 0; font-size: 24px;">MyHanut</h1>
      </div>
      <div style="background-color: #FDF6F0; padding: 30px; border-radius: 0 0 8px 8px;">
        <p style="color: #333; font-size: 16px;">Bonjour,</p>
        <p style="color: #555; font-size: 14px;">Utilisez le code ci-dessous pour ${actionLabel} :</p>
        <div style="background-color: #2D5016; color: white; font-size: 32px; font-weight: bold; text-align: center; padding: 20px; border-radius: 8px; letter-spacing: 8px; margin: 20px 0;">
          ${code}
        </div>
        <p style="color: #888; font-size: 12px;">Ce code expire dans <strong>15 minutes</strong>. Ne le partagez avec personne.</p>
      </div>
    </div>
  `;

  await transporter.sendMail({
    from: process.env.SMTP_FROM || `"MyHanut" <${process.env.SMTP_USER}>`,
    to: email,
    subject,
    html,
  });
};

module.exports = { generateOTP, sendOTP };
