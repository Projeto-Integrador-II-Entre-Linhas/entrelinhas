import express from "express";
const router = express.Router();

router.get("/reset/:token", (req, res) => {
  const token = req.params.token;

  const appUrl = `entrelinhas://app/reset-password/${token}`;

  res.send(`
    <html>
      <head>
        <meta http-equiv="refresh" content="0; url='${appUrl}'" />
      </head>
      <body>
        <p>Redirecionando para o aplicativo...</p>
      </body>
    </html>
  `);
});

export default router;
