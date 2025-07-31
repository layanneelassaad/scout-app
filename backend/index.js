
require('dotenv').config();
const express    = require('express');
const Stripe     = require('stripe');
const bodyParser = require('body-parser');
const cors       = require('cors');

const stripe = Stripe(process.env.STRIPE_SECRET_KEY);
const app    = express();

app.use(cors());
app.use(express.json());


const purchases = new Map();


const AGENTS = {
    'cross-app-summarizer': {
    name: 'Cross-App Summarizer',
    stripePriceId: 'price_1RqpR8K8vP5stg2ONdk6GXpK', 
    price: 7.99
  },
  'email-triage-draft': {
    name: 'Email Triage & Draft',
    stripePriceId: 'price_1RqnolK8vP5stg2Orp7RAIt1',
    price: 7.99
  },
  'meeting-note-taker': {
    name: 'Meeting Note-Taker',
    stripePriceId: 'price_1RqpSmK8vP5stg2OLEhk5kSt',
    price: 6.99
  },
  'modeler-agent': {
    name: '3D Modeler',
    stripePriceId: 'price_1RqozsK8vP5stg2OFHQiIWHB',
    price: 99.99
  },
  'data-scientist-agent': {
    name: 'Data Scientist',
    stripePriceId: 'price_def456',
    price: 149.99
  }
};


app.post('/create-checkout-session', async (req, res) => {
  const { agentId, userId } = req.body;
  const agent = AGENTS[agentId];
  if (!agent) return res.status(404).json({ error: 'Unknown agentId' });

  try {
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [{ price: agent.stripePriceId, quantity: 1 }],
      mode: 'payment',
      success_url: `myapp://purchase-success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url:  `myapp://store?canceled=true`,
      metadata: { agentId, userId }
    });
    res.json({ url: session.url });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});


app.post('/webhook', bodyParser.raw({ type: 'application/json' }), (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;
  try {
    event = stripe.webhooks.constructEvent(
      req.body,
      sig,
      process.env.STRIPE_WEBHOOK_SECRET
    );
  } catch (err) {
    console.error('⚠️ Webhook signature failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object;
    const { agentId, userId } = session.metadata;
    if (!purchases.has(userId)) purchases.set(userId, new Set());
    purchases.get(userId).add(agentId);
    console.log(`✅ User ${userId} purchased ${agentId}`);
  }

  res.json({ received: true });
});

const PORT = 4242;
app.listen(PORT, () => console.log(`🚀 Backend listening on http://localhost:${PORT}`));
