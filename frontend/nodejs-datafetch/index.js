const Moralis = require("moralis").default;

const express = require("express");
const cors = require("cors");
const cookieParser = require('cookie-parser');
const jwt = require('jsonwebtoken');
const { EvmChain } = require("@moralisweb3/common-evm-utils");

require('dotenv').config(); 


const app = express();
const port = 3000;


app.use(express.json());
app.use(cookieParser());

// allow access to Angular app domain
app.use(
  cors({
    origin: process.env.ANGULAR_URL,
    credentials: true,
  })
);

const MORALIS_API_KEY = "obnLC5KrnSb9sYNNQt1YMftN4rmkdX8i8F4jx1fGYmDxyBWF9JsZwdbUldThjKs3";
const address = "0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d";

// to use our .env variables

// for our server's method of setting a user session


const config = {
  domain: process.env.APP_DOMAIN,
  statement: 'Please sign this message to confirm your identity.',
  uri: process.env.ANGULAR_URL,
  timeout: 60,
};

app.post('/request-message', async (req, res) => {
  const { address, chain, network } = req.body;

  try {
    const message = await Moralis.Auth.requestMessage({
      address,
      chain,
      network,
      ...config,
    });

    res.status(200).json(message);
  } catch (error) {
    res.status(400).json({ error: error.message });
    console.error(error);
  }
});

app.post('/verify', async (req, res) => {
  try {
    const { message, signature } = req.body;

    const { address, profileId } = (
      await Moralis.Auth.verify({
        message,
        signature,
        networkType: 'evm',
      })
    ).raw;

    const user = { address, profileId, signature };

    // create JWT token
    const token = jwt.sign(user, process.env.AUTH_SECRET);

    // set JWT cookie
    res.cookie('jwt', token, {
      httpOnly: true,
    });

    res.status(200).json(user);
  } catch (error) {
    res.status(400).json({ error: error.message });
    console.error(error);
  }
});

app.get('/authenticate', async (req, res) => {
  const token = req.cookies.jwt;
  if (!token) return res.sendStatus(403); // if the user did not send a jwt token, they are unauthorized

  try {
    const data = jwt.verify(token, process.env.AUTH_SECRET);
    res.json(data);
  } catch {
    return res.sendStatus(403);
  }
});

app.get('/logout', async (req, res) => {
  try {
    res.clearCookie('jwt');
    return res.sendStatus(200);
  } catch {
    return res.sendStatus(403);
  }
}); 

app.get("/balances", async (req, res) => {
  try {
    // Promise.all() for receiving data async from two endpoints
    const [nativeBalance, tokenBalances] = await Promise.all([
      Moralis.EvmApi.balance.getNativeBalance({
        chain: EvmChain.ETHEREUM,
        address,
      }),
      Moralis.EvmApi.token.getWalletTokenBalances({
        chain: EvmChain.ETHEREUM,
        address,
      }),
    ]);
    res.status(200).json({
      // formatting the output
      address,
      nativeBalance: nativeBalance.result.balance.ether,
      tokenBalances: tokenBalances.result.map((token) => token.display()),
    });
  } catch (error) {
    // Handle errors
    console.error(error);
    res.status(500);
    res.json({ error: error.message });
  }
});

const startServer = async () => {
  await Moralis.start({
    apiKey: process.env.MORALIS_API_KEY,
  });

  app.listen(port, () => {
    console.log(`Example app listening on port ${port}`);
  });
};

startServer();