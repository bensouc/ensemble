# Abonnement sur facture (mandat administratif)

Pour les écoles qui paient sur facture et non par carte — cas d'Alain Fournier.

Jusqu'ici ces abonnements étaient saisis à la main dans `/admin`. Ce n'était pas
un choix : le webhook ne savait pas créer une ligne d'abonnement, il ne savait
que la mettre à jour. C'est corrigé. **Ne créez plus de ligne à la main.**

---

## Pourquoi passer par Stripe

Une souscription en `collection_method: "send_invoice"` n'encaisse rien. Stripe
émet une facture numérotée, l'école règle par virement ou mandat, et vous marquez
la facture payée. Ce que vous y gagnez sur la saisie manuelle :

- le renouvellement et les factures suivantes se font seuls
- des factures numérotées, ce que réclame le service comptable d'une école
- la quantité de classes se change dans le Dashboard et redescend dans l'app
- les statuts arrivent par le webhook : `valid_subscription?` et le plafond de
  création de classe deviennent justes sans intervention

---

## Créer l'abonnement

Dans le Dashboard Stripe, **en mode Live**.

1. Ouvrir le client de l'école. Son identifiant est dans la base :

   ```ruby
   School.find_by(name: "…").stripe_customer_id
   ```

   S'il est vide, l'école n'a pas encore de client Stripe. Ouvrez une fois la
   page d'abonnement depuis un compte de cette école : `StripeHelper` le crée.

2. **Create subscription** :
   - produit **Ensemble !!**, prix **annuel** (paliers : ≤2 → 50 €, ≤4 → 49 €,
     ≤6 → 48 €, ≤8 → 47 €, au-delà → 46 €)
   - **quantité = nombre de classes** — c'est ce qui plafonne la création dans
     l'app
   - mode de collecte **Email invoice**, délai de paiement **30 jours**
   - **pas de période d'essai**

3. **Si l'école a déjà payé une période**, calez `billing_cycle_anchor` sur la
   date de fin déjà réglée. Sans ça, Stripe émet une facture immédiatement pour
   une période que l'école a déjà payée.

   La date figure sur la ligne existante :

   ```ruby
   School.find_by(name: "…").subscription.current_period_end
   ```

---

## Vérifier que la synchronisation a eu lieu

Deux minutes après la création :

```ruby
s = School.find_by(name: "…").subscription
[s.stripe_subscription_id, s.status, s.quantity, s.rythm, s.current_period_end]
```

- `stripe_subscription_id` doit être rempli. **S'il est vide, rien n'a été reçu.**
- `status` doit être `active`
- `quantity` doit valoir le nombre de classes payées

Si la ligne existait déjà, elle est **adoptée** — le webhook la met à jour au lieu
d'en créer une seconde. C'est voulu : l'historique est conservé.

En cas de silence, Dashboard → **Developers → Events** → l'événement
`customer.subscription.created` → onglet des tentatives de livraison. Le webhook
acquitte désormais tout ce qu'il reçoit ; un échec y sera visible.

---

## À chaque échéance

1. Stripe émet la facture et l'envoie à l'école
2. L'école règle par virement ou mandat
3. Vous marquez la facture **Mark as paid** (paiement hors bande)
4. Le statut repasse `active` tout seul

**Entre l'émission et le paiement**, le statut est `past_due`. C'est délibérément
un statut qui **conserve l'accès** (`ACCESS_GRANTING_STATUSES`) : un mandat
administratif met des semaines, il n'est pas question de couper une école qui
attend son virement.

---

## Ce qu'il ne faut pas faire

**Ne créez plus de ligne `Subscription` dans `/admin`.** Une ligne créée à la
main avec un `stripe_subscription_id` vide est invisible du webhook. Elle
fonctionne par raccroc — le webhook retombe sur `school.subscription` — mais rien
ne garantit qu'elle corresponde à la réalité Stripe.

**Ne supprimez pas la ligne existante d'une école qu'on bascule.** Le webhook
l'adopte. La détruire perd l'historique et recrée le problème.

**Ne modifiez pas `quantity` à la main.** C'est Stripe qui fait foi ; le prochain
événement écrasera votre saisie. Changez la quantité dans le Dashboard.

---

## Quand quelque chose cloche

| Symptôme | Cause probable |
|---|---|
| `stripe_subscription_id` reste vide | l'événement n'est pas arrivé — voir Developers → Events |
| « client Stripe inconnu en base » dans les logs | `schools.stripe_customer_id` ne correspond à aucune école |
| L'école ne peut pas créer de classe | statut hors `active` / `trialing` / `past_due`, ou `classrooms_total >= quantity` |
| La page École n'affiche pas l'abonnement | la ligne n'existe pas — l'événement n'a jamais été traité |

Les journaux sont préfixés `[stripe]` :

```bash
grep '\[stripe\]' log/production.log | tail -20
```

---

## Le plafond de classes

`ClassroomPolicy#sub_limit?` autorise la création tant que
`classrooms_total < subscription.quantity`. `classrooms_total` **exclut les
classes créées par un compte admin** : le support peut créer des classes de test
dans une école sans consommer son quota.

Le statut compte autant que le nombre : un abonnement `canceled`, `unpaid` ou
`incomplete` ferme la création, même sous le plafond.

---

## Développement

Ne travaillez jamais sur ce sujet avec les clés de production. Le `.env` local
doit porter les clés **test mode** — clé API, clé publiable, identifiants de prix
et de table tarifaire, tous propres au mode.

`bin/rails stripe:clone_to_test` recrée produit et prix en test mode à partir du
live. Elle doit tourner **avant** de basculer `STRIPE_API_KEY`, puisque c'est
cette clé qui lit la source. La table tarifaire n'est pas clonable : l'API Stripe
n'expose aucune ressource « pricing table ».

Pour rejouer un événement en local :

```bash
stripe listen --forward-to localhost:3000/stripe-webhooks
```

Une charge utile réelle d'abonnement sur facture est conservée dans
`spec/fixtures/stripe/customer_subscription_created.json` et sert de base aux
tests de `Stripesubscription`.
