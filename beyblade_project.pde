// --- PARAMÈTRES GÉNÉRAUX ---
double dt = 0.015;
double t = 0;
double courbure = 0.0010;
double R_arene = 380;
double g = 9.81;

// On déclare deux objets Toupie
Toupie t1;
Toupie t2;

void setup() {
  size(800, 800, P3D);
  noStroke();
  
  // Initialisation des deux toupies avec des positions/couleurs différentes
  // (x, y, couleur)
  t1 = new Toupie(-100, 0, color(150, 170, 255)); 
  t2 = new Toupie(100, 0, color(255, 100, 100));
}

void draw() {
  background(30);
  ambientLight(100, 100, 100);
  directionalLight(255, 255, 255, 0, 1, -1);
  
  // Caméra qui suit le centre de l'action (moyenne des positions) ou fixe
  float camX = (float)(t1.x + t2.x) / 2 * 0.4;
  float camY = (float)(t1.y + t2.y) / 2 * 0.4 - 600;
  camera(camX, camY, 800, 0, 0, 0, 0, 0, -1);

  drawArena();
  
  // Mise à jour physique et affichage
  t1.update();
  t2.update();
  
  // GESTION COLLISION ENTRE TOUPIES
  gererCollision(t1, t2);
  
  t1.display();
  t2.display();
  
  // HUD global
  checkHUD();
  
  t += dt;
}

// -------------------------------------------------------
// GESTION DES COLLISIONS (Rebond élastique simple)
// -------------------------------------------------------
void gererCollision(Toupie a, Toupie b) {
  double dx = a.x - b.x;
  double dy = a.y - b.y;
  double distance = Math.sqrt(dx*dx + dy*dy);
  double rayonContact = a.rayon_disque + b.rayon_disque; // 20 + 20 = 40
  
  if (distance < rayonContact) {
    // 1. Calcul de la normale et de la tangente
    double nx = dx / distance;
    double ny = dy / distance;
    
    // 2. Correction de position (pour qu'elles ne s'imbriquent pas)
    double overlap = rayonContact - distance;
    a.x += nx * overlap / 2;
    a.y += ny * overlap / 2;
    b.x -= nx * overlap / 2;
    b.y -= ny * overlap / 2;
    
    // 3. Changement des vitesses (Choc élastique simple)
    // On projette la vitesse sur le vecteur normal
    double v1n = a.vx * nx + a.vy * ny;
    double v2n = b.vx * nx + b.vy * ny;
    
    // Si elles se rapprochent
    if (v1n - v2n < 0) {
      // Echange d'impulsion (masse égale m=1)
      // Coefficient de restitution (0.8 = rebond un peu amorti)
      double restitution = 0.8; 
      
      double j = -(1 + restitution) * (v1n - v2n) / 2; // division par 2 car masses égales (1/m1 + 1/m2)
      
      a.vx += j * nx;
      a.vy += j * ny;
      b.vx -= j * nx;
      b.vy -= j * ny;
      
      // Petit effet : le choc fait perdre un peu de rotation (frottement)
      a.omega_phi *= 0.95;
      b.omega_phi *= 0.95;
    }
  }
}

void mousePressed() {
  t1.lancer(-1); // Lance à gauche
  t2.lancer(1);  // Lance à droite
}

void checkHUD() {
  camera(); hint(DISABLE_DEPTH_TEST);
  fill(255); textSize(16); textAlign(LEFT);
  text("T1 (Bleu): " + (int)t1.omega_phi + " rad/s", 20, 30);
  text("T2 (Rouge): " + (int)t2.omega_phi + " rad/s", 20, 50);
  
  if (!t1.lancee && !t2.lancee) {
     textAlign(CENTER); textSize(24);
     text("CLIQUER POUR LANCER LE DUEL", width/2, height/2);
  }
  hint(ENABLE_DEPTH_TEST);
}

// -------------------------------------------------------
// CLASSE TOUPIE (Ta logique encapsulée)
// -------------------------------------------------------
class Toupie {
  // État
  double x, y, z;
  double vx, vy;
  double theta = 0.2;
  double phi = 0;
  double omega_phi = 0;
  double omega_theta = 0;
  boolean lancee = false;
  
  // Physique
  double m = 1.0;
  double L = 50;                
  double C = 10;                
  double A = 5;
  float rayon_disque = 20.0;
  
  // Frottements
  double frot_air = 0.035;
  double frot_sol = 0.008;
  double frot_pointe = 0.8;
  double facteur_drive = 0.25;
  double seuil_critique = 15.0;
  
  color c; // Couleur de la toupie
  
  Toupie(double startX, double startY, color col) {
    x = startX;
    y = startY;
    c = col;
  }
  
  void lancer(int direction) {
    lancee = true;
    x = direction * 150; // Position de départ
    y = 0;
    
    // On les lance l'une vers l'autre
    vx = -direction * 3.0 + random(-0.5, 0.5);
    vy = random(-1, 1);
    
    omega_phi = 60; // Vitesse de rotation initiale
    theta = 0.2;
    omega_theta = 0;
  }
  
  void update() {
    if (!lancee) return;
    
    // --- 1. DÉPLACEMENT (Ton code original) ---
    double r = Math.sqrt(x*x + y*y);
    double angle_pos = Math.atan2(y, x);
    double angle_pente = Math.atan(2 * courbure * r);
    
    double F_rappel = -m * g * Math.sin(angle_pente);
    double F_centri = omega_phi * 0.01;
    
    double force_tangentielle = 0;
    if (theta < PI/2 - 0.1) {
       force_tangentielle = omega_phi * Math.sin(theta) * facteur_drive;
    }

    double F_radial = F_rappel + F_centri;
    double ax = F_radial * Math.cos(angle_pos);
    double ay = F_radial * Math.sin(angle_pos);
    
    ax += force_tangentielle * Math.cos(angle_pos + PI/2);
    ay += force_tangentielle * Math.sin(angle_pos + PI/2);
    
    vx += ax * dt; vy += ay * dt;
    vx -= vx * frot_sol; vy -= vy * frot_sol;
    
    // Mur
    if (r > R_arene) {
       double nx = Math.cos(angle_pos);
       double ny = Math.sin(angle_pos);
       x = nx * (R_arene - 2); y = ny * (R_arene - 2);
       double v_dot = vx*nx + vy*ny;
       if(v_dot > 0) {
         vx -= 1.2 * v_dot * nx;
         vy -= 1.2 * v_dot * ny;
         omega_phi *= 0.8;
       }
    }
    
    x += vx; y += vy;
    z = courbure * x * x + courbure * y * y;
    
    // --- 2. ROTATION ---
    double acc_theta = (m * g * L * Math.sin(theta) - A * omega_phi * omega_phi * Math.cos(theta) * Math.sin(theta)) / C;
    if (omega_phi < seuil_critique) {
       double faiblesse = (seuil_critique - omega_phi) / seuil_critique;
       acc_theta += 2.5 * faiblesse; 
    }
    acc_theta -= 0.3 * omega_theta; 
    omega_theta += acc_theta * dt;
    theta += omega_theta * dt;
    
    if(theta < 0.05) theta = 0.05;
    omega_phi -= frot_air * omega_phi * dt;
    if (omega_phi > 0) omega_phi -= frot_pointe * dt;
    
    if(theta > 0.5) { omega_phi -= 2.0 * dt; vx *= 0.96; vy *= 0.96; }
    if (omega_phi < 0) omega_phi = 0;
    
    if(theta > PI/2 - 0.1) {
      theta = PI/2 - 0.1; omega_phi = 0; vx = 0; vy = 0;
    }
    phi += omega_phi * dt;
  }
  
  void display() {
    if (lancee || (!lancee && frameCount % 30 < 15)) { 
      pushMatrix();
      translate((float)x, (float)y, (float)z);
      
      float lift = (float)Math.sin(theta) * rayon_disque;
      if (lift < 4.0) lift = 0; else lift -= 4.0;
      translate(0, 0, lift);
      
      rotateZ((float)phi);   
      rotateY((float)theta); 
      
      // Dessin personnalisé
      pushMatrix();
      translate(0,0,(float) L);
      rotateX(PI);
      fill(100); 
      drawCone(4,(float) L, 10); 
      popMatrix();

      translate(0,0,(float) L);
      fill(c); // Utilise la couleur de l'objet
      cylinder(rayon_disque, 4);

      fill(255,255,0);
      translate(15, 0, 2);
      box(5);
      popMatrix();
    }
  }
}

// --- FONCTIONS GRAPHIQUES (Inchangées ou presque) ---
void drawArena() {
  fill(60);
  for (float r = 0; r < R_arene; r += 20) {
    float h1 = (float)(courbure * r * r);
    float h2 = (float)(courbure * (r+20) * (r+20));
    if((r/20)%2==0) fill(55); else fill(60);
    beginShape(QUAD_STRIP);
    for(int d=0; d<=360; d+=10) {
      float a = radians(d);
      vertex(cos(a)*r, sin(a)*r, h1);
      vertex(cos(a)*(r+20), sin(a)*(r+20), h2);
    }
    endShape();
  }
}

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
  beginShape(TRIANGLE_FAN); vertex(0, 0, 0);
  for (int i = sides; i >= 0; i--) vertex(cos(angle * i) * r, sin(angle * i) * r, 0);
  endShape();
}

void cylinder(float r, float h) {
  int sides = 30; float angle = TWO_PI / sides;
  beginShape(QUAD_STRIP);
  for (int i = 0; i <= sides; i++) {
    float x = cos(angle * i) * r;
    float y = sin(angle * i) * r;
    vertex(x, y, 0); vertex(x, y, h);
  }
  endShape();
  beginShape(TRIANGLE_FAN);
  vertex(0, 0, h); for (int i = 0; i <= sides; i++) vertex(cos(angle * i) * r, sin(angle * i) * r, h);
  endShape();
  beginShape(TRIANGLE_FAN); vertex(0, 0, 0); for (int i = sides; i >= 0; i--) vertex(cos(angle * i) * r, sin(angle * i) * r, 0);
  endShape();
}
