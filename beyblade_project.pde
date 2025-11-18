/*
 * MODÉLISATION 3D D'UNE TOUPIE BEYBLADE
 * 
 * Basé sur vos notes au tableau :
 * - (theta) : angle d'inclinaison de la toupie
 * - (phi) : angle de rotation autour de l'axe z
 * - (omega) : vitesse angulaire de rotation
 * 
 */

// PARAMÈTRES 
double dt = 0.01;              // Pas de temps
double t = 0;                  // Chronomètre

// ÉTAT DE LA TOUPIE 
// Position du centre de masse
double x = 0, y = 0, z = 0;

// Angles
double theta = 0;            // Inclinaison (0 = vertical, PI/2 = horizontal)
double phi = 0;                // Rotation autour de z

// Vitesses angulaires
double omega_phi = 40;         // Vitesse de rotation (tourne sur elle-même)
double omega_theta = 10;        // Vitesse d'inclinaison

// Paramètres physiques
double m = 1.0;                // Masse
double g = 9.81;               // Gravité
double L = 50;                 // Longueur (hauteur de la toupie)
double C = 10;                 // Constante liée au moment d'inertie
double A = 5;                  // Autre constante d'inertie

// Frottements
double friction_phi = 0.;     // Frottement rotation
double friction_theta = 0.;   // Frottement inclinaison

void setup() {
  size(800, 800, P3D);
}

void draw() {
  background(30);
  
  // CAMÉRA 
  camera(200, -100, 200, 0, 0, 0, 0, 0, -1);
  lights();
  
  // SOL
  fill(50);
  box(600, 600, 1);
  
  // MISE À JOUR PHYSIQUE
  
  // Équation du mouvement pour theta (simplifiée de vos notes)
  // theta_dot_dot = (m*g*L*sin(theta) - A*phi_dot*omega*cos(theta)*sin(theta)) / C
  double acceleration_theta = (m * g * L * sin((float)theta) 
                               - A * omega_phi * omega_phi * cos((float)theta) * sin((float)theta)) / C;
  
  // Frottement sur theta
  acceleration_theta -= friction_theta * omega_theta;
  
  // Mise à jour de omega_theta
  omega_theta += acceleration_theta * dt;
  
  // Mise à jour de theta
  theta += omega_theta * dt;
  
  // Limiter theta entre 0 et PI/2 (la toupie ne se retourne pas)
  if (theta < 0.05) theta = 0.05;
  if (theta > PI/2 - 0.1) {
    theta = PI/2 - 0.1;  // Toupie couchée = arrêtée
    omega_phi = 0;
    omega_theta = 0;
  }
  
  // Si la toupie tourne trop lentement, elle commence à tomber
  if (omega_phi < 5) {
    omega_theta += 2.0 * dt;  // Accélère la chute
    omega_phi -= 0.5 * dt;    // Ralentit encore plus
    if (omega_phi < 0) omega_phi = 0;
  }
  
  // Frottement sur la rotation phi (plus fort quand elle penche)
  double friction_actuelle = friction_phi * (1 + 3 * theta);
  omega_phi -= friction_actuelle * omega_phi * dt;
  
  // Mise à jour de phi
  phi += omega_phi * dt;
  
  // Si la toupie tourne trop lentement, elle tombe
  if (omega_phi < 1) {
    omega_theta += 0.5 * dt;  // Accélère la chute
  }
  
  // DESSIN DE LA TOUPIE
  pushMatrix();
  
  // Position du point de contact avec le sol (la pointe)
  translate((float)x, (float)y, (float)z);
  
  // Rotation de précession (autour de z)
  rotateZ((float)phi);
  
  // Inclinaison
  rotateY((float)theta);
   // LA POINTE 
 fill(100, 100, 100);
  pushMatrix();
  fill(150, 170, 255);
  translate(0,0,(float) L);
  rotateX(PI);
  drawCone(4,(float)  L, 10);  // Petite pointe métallique
  popMatrix();
  
  translate(0,0,(float) L);
  // LE DESSUS
  fill(150, 170, 255);
  cylinder(20, 4);
  popMatrix();
  /*
  // FORME DE TOUPIE RÉALISTE
  noStroke();
  
  // LA POINTE 
  fill(100, 100, 100);
  pushMatrix();
  rotateX(PI);
  drawCone(4, 12, 20);  // Petite pointe métallique
  popMatrix();
  
  // LE GROS DISQUE ROND 
  fill(100, 150, 255);
  translate(0, 0, -25);  // Monter un peu
  sphere(30);  // Grande sphère aplatie = le corps rond
  popMatrix();
  
  // Aplatir le disque avec un cylindre
  fill(80, 130, 230);
  pushMatrix();
  translate(0, 0, -25);
  rotateX(PI/2);
  cylinder(32, 10);  // Disque plat
  popMatrix();
  
  // LE DESSUS
  fill(150, 170, 255);
  pushMatrix();
  translate(0, 0, -35);
  rotateX(PI/2);
  cylinder(12, 15);
  popMatrix();
  
  // Ligne pour voir la rotation
  stroke(255, 200, 0);
  strokeWeight(3);
  line(0, 0, -25, 32, 0, -25);
 
  popMatrix();
  */
  // AFFICHAGE DES INFOS 
  camera();
  fill(255);
  textAlign(LEFT);
  text("Temps: " + nf((float)t, 1, 1) + "s", 10, 20);
  text("Theta (inclinaison): " + nf((float)degrees((float)theta), 1, 1) + "°", 10, 40);
  text("Omega_phi (rotation): " + nf((float)omega_phi, 1, 1) + " rad/s", 10, 60);
  
  if (omega_phi < 1) {
    text("La toupie tombe !", 10, 80);
    fill(255, 0, 0);
  }
  
  // État de la toupie
  if (theta > 1.0) {
    fill(255, 100, 0);
    text("ATTENTION : Toupie instable !", 10, 100);
  }
  if (theta > 1.3) {
    fill(255, 0, 0);
    text("TOMBÉE !", 10, 120);
  }
  
  t += dt;
}

// Fonction pour dessiner un cône
void drawCone(float r, float h, int sides) {
  float angle = TWO_PI / sides;
  
  // Côtés du cône
  beginShape(TRIANGLES);
  for (int i = 0; i < sides; i++) {
    float x1 = cos(angle * i) * r;
    float y1 = sin(angle * i) * r;
    float x2 = cos(angle * (i + 1)) * r;
    float y2 = sin(angle * (i + 1)) * r;
    
    vertex(0, 0, h);      // Pointe
    vertex(x1, y1, 0);    // Base
    vertex(x2, y2, 0);    // Base
  }
  endShape();
  
  // Base du cône
  beginShape(TRIANGLE_FAN);
  vertex(0, 0, 0);
  for (int i = sides; i >= 0; i--) {
    float x = cos(angle * i) * r;
    float y = sin(angle * i) * r;
    vertex(x, y, 0);
  }
  endShape();
}

// Fonction pour dessiner un cylindre
void cylinder(float r, float h) {
  int sides = 30;
  float angle = TWO_PI / sides;
  
  // Dessiner les côtés
  beginShape(QUAD_STRIP);
  for (int i = 0; i <= sides; i++) {
    float x = cos(angle * i) * r;
    float y = sin(angle * i) * r;
    vertex(x, y, 0);
    vertex(x, y, h);
  }
  endShape();
  
  // Dessiner le dessus
  beginShape(TRIANGLE_FAN);
  vertex(0, 0, h);
  for (int i = 0; i <= sides; i++) {
    float x = cos(angle * i) * r;
    float y = sin(angle * i) * r;
    vertex(x, y, h);
  }
  endShape();
  
  // Dessiner le dessous
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
  // Relancer avec des valeurs aléatoires
  theta = random(0.05, 0.3);
  omega_phi = random(30, 50);
  omega_theta = 0;
  phi = 0;
  t = 0;
}
