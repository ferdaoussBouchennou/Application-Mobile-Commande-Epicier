const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST || process.env.SMTP_HOST || 'smtp.gmail.com',
  port: parseInt(process.env.EMAIL_PORT || process.env.SMTP_PORT || '587'),
  secure: false, // true for 465, false for 587
  auth: {
    user: process.env.EMAIL_USER || process.env.SMTP_USER,
    pass: process.env.EMAIL_PASS || process.env.SMTP_PASS,
  },
});

// Mode développement (si pas d'email configuré)
const isEmailConfigured = (process.env.EMAIL_USER && process.env.EMAIL_USER !== 'hafsazohri0@gmail.com') || 
                          (process.env.SMTP_USER && process.env.SMTP_USER !== 'your_email@example.com');

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

  if (!isEmailConfigured) {
    console.log('--- DEVELOPMENT MODE: OTP Sent to Console ---');
    console.log(`To: ${email}`);
    console.log(`Subject: ${subject}`);
    console.log(`CODE: ${code}`);
    console.log('---------------------------------------------');
    return;
  }

  try {
    await transporter.sendMail({
      from: process.env.SMTP_FROM || `"MyHanut" <${process.env.EMAIL_USER || process.env.SMTP_USER}>`,
      to: email,
      subject,
      html,
    });
  } catch (error) {
    console.error('Erreur lors de l\'envoi de l\'email (transporter.sendMail):', error);
    throw new Error('Impossible d\'envoyer le code de vérification.');
  }
};

/**
 * Send an email to an epicier when their registration is accepted or rejected
 * @param {string} email
 * @param {string} nom
 * @param {string} status 'ACCEPTE', 'COMPLETE', or 'REFUSE'
 */
const sendEpicierStatusEmail = async (email, nom, status) => {
  const isAccepted = status === 'ACCEPTE' || status === 'COMPLETE';
  const subject = isAccepted ? 'MyHanut - Demande d\'inscription acceptée' : 'MyHanut - Demande d\'inscription refusée';
  
  const content = isAccepted 
    ? `<p style="color: #333; font-size: 16px;">Félicitations ${nom},</p>
       <p style="color: #555; font-size: 14px;">Votre demande d'inscription en tant qu'épicier a été <strong>acceptée</strong> par l'administrateur.</p>
       <p style="color: #555; font-size: 14px;">Vous pouvez dès à présent vous connecter à l'application MyHanut Epicier avec vos identifiants.</p>`
    : `<p style="color: #333; font-size: 16px;">Bonjour ${nom},</p>
       <p style="color: #555; font-size: 14px;">Suite à l'examen de votre demande d'inscription, nous avons le regret de vous informer qu'elle a été <strong>refusée</strong>.</p>
       <p style="color: #555; font-size: 14px;">Pour plus d'informations, veuillez contacter le support MyHanut.</p>`;

  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto;">
      <div style="background-color: #2D5016; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
        <h1 style="color: white; margin: 0; font-size: 24px;">MyHanut</h1>
      </div>
      <div style="background-color: #FDF6F0; padding: 30px; border-radius: 0 0 8px 8px;">
        ${content}
      </div>
    </div>
  `;

  if (!isEmailConfigured) {
    console.log('--- DEVELOPMENT MODE: Status Email Sent to Console ---');
    console.log(`To: ${email}`);
    console.log(`Subject: ${subject}`);
    console.log(`Status: ${status}`);
    console.log('----------------------------------------------------');
    return;
  }

  try {
    await transporter.sendMail({
      from: process.env.SMTP_FROM || `"MyHanut" <${process.env.EMAIL_USER || process.env.SMTP_USER}>`,
      to: email,
      subject,
      html,
    });
  } catch (error) {
    console.error('Erreur lors de l\'envoi de l\'email de statut:', error);
  }
};

module.exports = { generateOTP, sendOTP, sendEpicierStatusEmail };
