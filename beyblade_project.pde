/*
 * PROJET MODÉLISATION MATHÉMATIQUE - R5.12
 * 
 * PROBLÉMATIQUE : 
 * Quelle toupie gagne : la légère et rapide ou la lourde et lente ?
 * 
 * MODÈLE SIMPLE :
 * - 2 toupies qui partent du centre
 * - Elles ralentissent à cause du frottement
 * - Elles rebondissent sur les bords et entre elles
 * - L'arène a une petite pente vers le centre
 */

// === PARAMÈTRES ===
double dt = 0.01;              // Petit pas de temps
double t = 0;                  // Chronomètre
int viewSize = 800;            // Taille de la fenêtre
double arenaRadius = 300;      // Taille de l'arène

double frottement = 0.50;      // Ralentissement (PETIT = dure longtemps)
double pente = 200;             // Force qui pousse vers le centre (comme un bol)

// === UNE TOUPIE ===
class Beyblade {
  double x, y;           // Position
  double vx, vy;         // Vitesse
  double rotation;       // Vitesse de rotation
  double angle;          // Angle pour dessiner
  double masse;          // Poids
  double rayon;          // Taille
  int couleur;           // Couleur
  boolean tourne;        // Est-ce qu'elle tourne encore ?
  
  Beyblade(double vitesse, double rot, double m, double r, int c) {
    // Départ aléatoire près du bord de l'arène
    double angleDepart = random(0, TWO_PI);
    double distanceDepart = arenaRadius * 0.7;  // À 70% du rayon
    x = distanceDepart * cos((float)angleDepart);
    y = distanceDepart * sin((float)angleDepart);
    
    // Direction aléatoire vers le centre (angle opposé)
    double direction = angleDepart + PI + random(-0.5, 0.5);
    vx = vitesse * cos((float)direction);
    vy = vitesse * sin((float)direction);
    
    rotation = rot;
    angle = 0;
    masse = m;
    rayon = r;
    couleur = c;
    tourne = true;
  }
  
  void bouger() {
    if (!tourne) return;
    
    // La pente pousse vers le centre
    double distance = sqrt((float)(x*x + y*y));
    if (distance > 0) {
      vx -= pente * x / distance * dt;
      vy -= pente * y / distance * dt;
    }
    
    // Le frottement ralentit
    vx -= frottement * vx * dt;
    vy -= frottement * vy * dt;
    rotation -= frottement * rotation * dt;
    
    // Avancer
    x += vx * dt;
    y += vy * dt;
    angle += rotation * dt;
    
    // Rebondir sur le bord
    if (distance + rayon > arenaRadius) {
      double nx = x / distance;
      double ny = y / distance;
      double rebond = vx * nx + vy * ny;
      vx -= 2 * rebond * nx;
      vy -= 2 * rebond * ny;
      x = nx * (arenaRadius - rayon);
      y = ny * (arenaRadius - rayon);
    }
    
    // Arrêter si trop lent
    if (abs((float)rotation) < 0.10) {
      tourne = false;
    }
  }
  
  void dessiner() {
    fill(couleur, tourne ? 255 : 100);
    stroke(255);
    strokeWeight(2);
    circle((float)x, (float)y, (float)(2*rayon));
    
    if (tourne) {
      pushMatrix();
      translate((float)x, (float)y);
      rotate((float)angle);
      line(0, 0, (float)rayon, 0);
      popMatrix();
    }
  }
}

Beyblade toupie1, toupie2;

void settings() {
  size(viewSize, viewSize);
}

void setup() {
  // Toupie ROUGE : légère et rapide
  toupie1 = new Beyblade(random(60, 100), random(40, 60), 0.8, 25, color(255, 50, 50));
  
  // Toupie BLEUE : lourde et lente
  toupie2 = new Beyblade(random(40, 70), random(20, 40), 1.5, 35, color(50, 100, 255));
  
  t = 0;
}

void draw() {
  background(20);
  translate(viewSize/2, viewSize/2);
  scale(1, -1);
  
  // Dessiner l'arène (cercles pour faire la pente)
  for (int i = 5; i > 0; i--) {
    fill(30 + i*8);
    noStroke();
    circle(0, 0, 2*(float)arenaRadius * i/5);
  }
  
  // Bord de l'arène
  noFill();
  stroke(150);
  strokeWeight(4);
  circle(0, 0, 2*(float)arenaRadius);
  
  // Faire bouger les toupies
  toupie1.bouger();
  toupie2.bouger();
  
  // Vérifier si elles se touchent
  double dx = toupie2.x - toupie1.x;
  double dy = toupie2.y - toupie1.y;
  double distance = sqrt((float)(dx*dx + dy*dy));
  
  if (distance < toupie1.rayon + toupie2.rayon && toupie1.tourne && toupie2.tourne) {
    // Elles se touchent ! Collision avec les masses
    double nx = dx / distance;
    double ny = dy / distance;
    
    // Vitesses dans la direction de collision
    double v1n = toupie1.vx * nx + toupie1.vy * ny;
    double v2n = toupie2.vx * nx + toupie2.vy * ny;
    
    // Seulement si elles s'approchent
    if (v1n - v2n > 0) {
      // Conservation de la quantité de mouvement (plus c'est lourd, moins ça bouge)
      double m1 = toupie1.masse;
      double m2 = toupie2.masse;
      double somme = m1 + m2;
      
      // Nouvelles vitesses après collision (avec rebond fort)
      double v1n_new = ((m1 - m2) * v1n + 2 * m2 * v2n) / somme;
      double v2n_new = ((m2 - m1) * v2n + 2 * m1 * v1n) / somme;
      
      // Appliquer les nouvelles vitesses
      toupie1.vx += (v1n_new - v1n) * nx;
      toupie1.vy += (v1n_new - v1n) * ny;
      toupie2.vx += (v2n_new - v2n) * nx;
      toupie2.vy += (v2n_new - v2n) * ny;
      
      // Séparer les toupies pour éviter qu'elles restent collées
      double overlap = (toupie1.rayon + toupie2.rayon - distance) / 2;
      toupie1.x -= overlap * nx;
      toupie1.y -= overlap * ny;
      toupie2.x += overlap * nx;
      toupie2.y += overlap * ny;
      
      // La rotation diminue un peu au choc (mais pas trop)
      toupie1.rotation *= 0.98;
      toupie2.rotation *= 0.98;
    }
  }
  
  // Dessiner les toupies
  toupie1.dessiner();
  toupie2.dessiner();
  
  // Afficher les infos
  scale(1, -1);
  fill(255);
  textAlign(LEFT);
  text("Temps: " + nf((float)t, 1, 1) + "s", -280, -280);
  
  String etat = "";
  if (toupie1.tourne && toupie2.tourne) etat = "Les 2 tournent";
  else if (toupie1.tourne) etat = "Rouge gagne !";
  else if (toupie2.tourne) etat = "Bleue gagne !";
  else etat = "Match nul";
  text(etat, -280, -260);
  
  t += dt;
}

void mousePressed() {
  setup();
}
