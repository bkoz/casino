# Project Benedict: The Cipher Breeze Heist

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│               🎰 CIPHER BREEZE CASINO 🎰                    │
│                                                             │
│              "Where Fortune Meets Cipher"                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 📜 The Story

Welcome to Vegas, baby!

You've been recruited for a delicate operation. Terry Benedict, the notorious casino magnate, runs the Cipher Breeze Casino on the Strip. Word on the street is he's gotten sloppy with his digital security. The casino floor has these fancy new kiosks - "Digital Concierge Services" they call them - meant to help guests view documents, make reservations, check their rewards points.

But here's the thing: these kiosks are connected to everything. And we mean *everything*.

Your job? Simple. Use one of these kiosks to access what you shouldn't. Benedict keeps something valuable locked away - a prize that proves he's not as untouchable as he thinks. The casino's vault holds more than just money; it holds secrets.

The question is: can you find them?

## 🎯 Your Objective

Pull off the perfect digital heist. No ski masks, no weapons, just your wits, a web browser and the `curl` command.

**The Prize:** Benedict's vault contains a flag that proves you've beaten the house. Get it, and you'll have pulled off what everyone said was impossible.

## 🎰 Getting Started

### Finding Your Way In

Using either the Openshift Console or the CLI, deploy the [casino-kiosk container image](https://ghcr.io/bkoz/casino). You should know how to do this by now. Make sure to set
the `STOLEN_SA_TOKEN=dummy_token` environment variable during deployment. This 
variable is not being used at this point but it is required for the container to start.

The word on the street is that there is an SSRF flaw in the kiosk application which 
could allow access to a vault which contains the flag via a secret protocol. 

Somewhere in the casino's systems, there's a secure storage vault. Our sources indicate Benedict uses non-standard protocols for internal communications. Creative, but potentially exploitable.

Next, using a web browser, visit the casino-kiosk URL and get started. As you visit various endpoints, clues will be given to help you advance to the next step.

Every good heist starts with reconnaissance. Look around. What does the kiosk do? What features does it have? What information does it volunteer?

That's all you need to get started. The rest? That's for you to figure out.

## 🃏 A Final Word

*"In this town, I'm the house. And house always wins."*  
— Terry Benedict

Prove him wrong.

---

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│              The casino is open 24/7.                       │
│                                                             │
│           Your table is waiting.                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```
