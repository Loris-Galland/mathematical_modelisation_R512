/*
 * MODÉLISATION 3D D'UNE TOUPIE BEYBLADE DANS UNE CUVE (STADE)
 */

// PARAMÈTRES 
double dt = 0.02;              // Pas de temps (Augmenté pour accélérer la simu)
double t = 0;                  // Chronomètre

// ÉTAT DE LA TOUPIE 
// Position de la pointe
double x = 150, y = 0, z = 0; // On commence sur le bord de la cuve (x=150)

// Variables pour la CUVE et le frottement 
double vx = 0, vy = 0;            // Vitesse de la pointe
double courbure = 0.0015;         // Forme de la cuve (z = courbure * dist^2)
double mu_sol = 0.05;             // Coefficient de frottement pointe/sol (glisse bien)

// Angles
double theta = 0.2;            // Inclinaison initiale (un peu penchée)
double phi = 0;                // Rotation autour de z

// Vitesses angulaires
double omega_phi = 50;         // Vitesse de rotation (tourne sur elle-même)
double omega_theta = 0;        // Vitesse d'inclinaison

// Paramètres physiques
double m = 1.0;                // Masse
double g = 9.81;               // Gravité
double L = 50;                 // Longueur (hauteur de la toupie)

// Rayon pour le calcul d'inertie
double R_objet = 20;           

double C = 10;                 // Constante liée au moment d'inertie
double A = 5;                  // Autre constante d'inertie

// Frottements réactivés 
double friction_phi = 0.08;     // Frottement rotation (air) - un peu plus fort pour voir l'arrêt
double friction_theta = 0.05;   // Frottement inclinaison (air)
// -------------------------------------------

// Variables pour l'énergie et la force
double energie_mecanique = 0;
double force_reaction = 0;

void setup() {
  size(800, 800, P3D);
  
  // Calcul automatique des constantes d'inertie (Approximation Cylindre)
  C = 0.5 * m * R_objet * R_objet;
  // Mise à l'échelle pour la simulation visuelle
  C = C / 20.0; 
  A = ( (1.0/12.0) * m * (3*R_objet*R_objet + L*L) + m * (L/2.0)*(L/2.0) ) / 20.0;
}

void draw() {
  background(30);
  
  // CAMÉRA (Vue un peu plus haute pour voir la cuve)
  camera(0, -500, 400, 0, 0, 0, 0, 0, -1);
  lights();
  
  // DESSIN DE LA CUVE
  // Au lieu d'une boite plate incliné, on dessine un "bol" gris simple
  noStroke();
  fill(50);
  pushMatrix();
  // On dessine la cuve comme une série de bandes circulaires
  for (float r = 0; r < 400; r += 20) {
    float h1 = (float)(courbure * r * r);
    float h2 = (float)(courbure * (r+20) * (r+20));
    beginShape(QUAD_STRIP);
    for (int deg = 0; deg <= 360; deg += 10) {
      float rad = radians(deg);
      float x1 = cos(rad) * r;
      float y1 = sin(rad) * r;
      float x2 = cos(rad) * (r+20);
      float y2 = sin(rad) * (r+20);
      vertex(x1, y1, h1);
      vertex(x2, y2, h2);
    }
    endShape();
  }
  popMatrix();
  
  // Physique de la pointe dans la CUVE
  
  // Calcul de la pente locale (dérivée de la parabole)
  double dist = Math.sqrt(x*x + y*y);
  double angle_pente_local = Math.atan(2 * courbure * dist);
  
  // Force de gravité projetée sur la pente (tire vers le centre 0,0)
  double F_gravite_pente = m * g * Math.sin(angle_pente_local);
  
  // On décompose cette force selon X et Y (direction vers le centre)
  double angle_pos = Math.atan2(y, x); // Angle polaire de la position
  double Fx_gravite = -F_gravite_pente * Math.cos(angle_pos);
  double Fy_gravite = -F_gravite_pente * Math.sin(angle_pos);
  
  // Force de frottement au sol
  double N = m * g * Math.cos(angle_pente_local); // Force normale
  double Fx_frot = -mu_sol * N * vx;
  double Fy_frot = -mu_sol * N * vy;
  
  // Accélération
  double ax = (Fx_gravite + Fx_frot) / m;
  double ay = (Fy_gravite + Fy_frot) / m;
  
  // Mise à jour vitesse et position
  vx += ax * dt;
  vy += ay * dt;
  x += vx * dt;
  y += vy * dt;
  
  // Mise à jour de la hauteur Z (sur la courbe)
  z = courbure * (x*x + y*y);
  
  
  // Équation du mouvement pour theta
  double acceleration_theta = (m * g * L * sin((float)theta) 
                               - A * omega_phi * omega_phi * cos((float)theta) * sin((float)theta)) / C;
  
  // Frottement sur theta
  acceleration_theta -= friction_theta * omega_theta;
  
  // Mise à jour de omega_theta
  omega_theta += acceleration_theta * dt;
  
  // Mise à jour de theta
  theta += omega_theta * dt;
  
  // Limiter theta
  if (theta < 0.05) theta = 0.05;
  
  // Gestion de la chute au sol
  // Si la toupie dépasse 90° (PI/2), elle touche par le coté
  if (theta > PI/2 - 0.1) {
    theta = PI/2 - 0.1;  // On bloque l'angle
    
    // Frottement violent car le corps touche le sol
    omega_phi -= 2.0 * dt; 
    vx *= 0.9; vy *= 0.9; // On freine le déplacement aussi
    omega_theta = 0;      // Plus de rebond
    
    if (omega_phi < 0) omega_phi = 0;
  }
  
  // Si la toupie tourne trop lentement, elle commence à tomber
  if (omega_phi < 10) {
    omega_theta += 3.0 * dt;  // Accélère la chute (plus fort avec dt augmenté)
  }
  
  // Frottement sur la rotation phi (air)
  double friction_actuelle = friction_phi * (1 + 3 * theta);
  omega_phi -= friction_actuelle * omega_phi * dt;
  
  // Mise à jour de phi
  phi += omega_phi * dt;
  
  
  // Calculs Énergie et Force 
  // Force normale au sol
  force_reaction = m * g * Math.cos(angle_pente_local); 
  
  // Énergie
  double h_cm = z + L * cos((float)theta); 
  double Ep = m * g * h_cm;
  double Ec_rot = 0.5 * C * omega_phi * omega_phi + 0.5 * A * omega_theta * omega_theta;
  double Ec_trans = 0.5 * m * (vx*vx + vy*vy);
  energie_mecanique = Ep + Ec_rot + Ec_trans;

  
  // DESSIN DE LA TOUPIE
  pushMatrix();
  
  // Position du point de contact
  translate((float)x, (float)y, (float)z);
  
  // Décalage visuel quand elle est couchée
  // Si elle tombe, on la remonte un peu pour que le flanc touche le sol, pas le centre
  if(theta > 0.5) {
     float ratio_chute = map((float)theta, 0.5, PI/2, 0, 1);
     translate(0, 0, (float)R_objet * ratio_chute);
  }

  // Dessin du vecteur Force de Réaction (Rouge)
  stroke(255, 0, 0); strokeWeight(3);
  line(0, 0, 0, 0, 0, (float)(force_reaction * 5)); 
  noStroke();
  
  // Rotation de précession (autour de z monde/local)
  rotateZ((float)phi);
  
  // Inclinaison (nutation)
  rotateY((float)theta);
  
  // Rotation sur elle-même (Spin visuel)
  rotateZ((float)(omega_phi * t)); // Ajout pour voir le cylindre tourner
  
   // LA POINTE
  fill(100, 100, 100);
  pushMatrix();
  fill(150, 170, 255);
  translate(0,0,(float) L);
  rotateX(PI);
  drawCone(4,(float)  L, 10); 
  popMatrix();
  
  translate(0,0,(float) L);
  // LE DESSUS
  fill(150, 170, 255);
  cylinder(20, 4);
  
  // Petit cube jaune pour voir qu'elle tourne sur elle même
  fill(255,255,0);
  translate(15, 0, 2);
  box(5);
  
  popMatrix();
  
  // AFFICHAGE DES INFOS 
  camera();
  fill(255);
  textAlign(LEFT);
  text("Temps (x2): " + nf((float)t, 1, 1) + "s", 10, 20);
  text("Theta: " + nf((float)degrees((float)theta), 1, 1) + "°", 10, 40);
  text("Omega_phi: " + nf((float)omega_phi, 1, 1) + " rad/s", 10, 60);
  text("Vitesse pointe: " + nf((float)sqrt((float)(vx*vx+vy*vy)), 1, 2) + " m/s", 10, 80);
  
  text("Energie Méca: " + nf((float)energie_mecanique, 4, 1) + " J", 10, 160);
  fill(255, 200, 0);
  text("(Frottements actifs)", 10, 180);
  fill(255);

  
  if (omega_phi < 1) {
    text("La toupie est au sol !", 10, 100);
    fill(255, 0, 0);
  }
  
  t += dt;
}

// Fonction pour dessiner un cône (Ton code original)
void drawCone(float r, float h, int sides) {
  float angle = TWO_PI / sides;
  beginShape(TRIANGLES);
  for (int i = 0; i < sides; i++) {
    float x1 = cos(angle * i) * r;
    float y1 = sin(angle * i) * r;
    float x2 = cos(angle * (i + 1)) * r;
    float y2 = sin(angle * (i + 1)) * r;
    vertex(0, 0, h); vertex(x1, y1, 0); vertex(x2, y2, 0);
  }
  endShape();
  beginShape(TRIANGLE_FAN);
  vertex(0, 0, 0);
  for (int i = sides; i >= 0; i--) {
    float x = cos(angle * i) * r;
    float y = sin(angle * i) * r;
    vertex(x, y, 0);
  }
  endShape();
}

// Fonction pour dessiner un cylindre (Ton code original)
void cylinder(float r, float h) {
  int sides = 30;
  float angle = TWO_PI / sides;
  beginShape(QUAD_STRIP);
  for (int i = 0; i <= sides; i++) {
    float x = cos(angle * i) * r;
    float y = sin(angle * i) * r;
    vertex(x, y, 0); vertex(x, y, h);
  }
  endShape();
  beginShape(TRIANGLE_FAN);
  vertex(0, 0, h);
  for (int i = 0; i <= sides; i++) {
    float x = cos(angle * i) * r;
    float y = sin(angle * i) * r;
    vertex(x, y, h);
  }
  endShape();
  beginShape(TRIANGLE_FAN);
  vertex(0, 0, 0);
  for (int i = sides; i >= 0; i--) {
    float x = cos(angle * i) * r;
    float y = sin(angle * i) * r;
    vertex(x, y, 0);
  }
  endShape();
}

void mousePressed() {
  // Relancer 
  theta = random(0.1, 0.3);
  omega_phi = random(40, 60);
  omega_theta = 0;
  phi = 0;
  t = 0;
  // Reset position sur le bord de la cuve
  x=150; y=0; z=0; vx=0; vy=0;
}
