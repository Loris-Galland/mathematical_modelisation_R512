// --- PARAMÈTRES GÉNÉRAUX ---
double dt = 0.015;
double t = 0;
double courbure = 0.0015; 
double R_arene = 380;
double g = 9.81;

Toupie t1;
Toupie t2;

void setup() {
  size(800, 800, P3D);
  noStroke();
  
  // --- CONFIGURATION DUEL ---
  // T1 (Bleue) : PETITE (Rayon x 0.8) - Rapide et agile
  t1 = new Toupie(-150, 0, color(100, 200, 255), 0.8); 
  
  // T2 (Rouge) : LARGE (Rayon x 1.5) - "Tank", lourde, stable, MAIS MÊME HAUTEUR
  t2 = new Toupie(150, 0, color(255, 100, 100), 1.5);  
}

void draw() {
  background(30);
  ambientLight(100, 100, 100);
  directionalLight(255, 255, 255, 0, 1, -1);
  
  // Caméra
  float camX = (float)(t1.x + t2.x) / 2 * 0.4;
  float camY = (float)(t1.y + t2.y) / 2 * 0.4 - 600;
  camera(camX, camY, 800, 0, 0, 0, 0, 0, -1);

  drawArena();
  
  t1.update();
  t2.update();
  
  gererCollision(t1, t2);
  
  t1.display();
  t2.display();
  
  checkHUD();
  
  t += dt;
}

// -------------------------------------------------------
// GESTION DES COLLISIONS
// -------------------------------------------------------
void gererCollision(Toupie a, Toupie b) {
  if (a.estCouchee() || b.estCouchee()) return; 

  double dx = a.x - b.x;
  double dy = a.y - b.y;
  double distance = Math.sqrt(dx*dx + dy*dy);
  
  // Somme des rayons réels (qui sont maintenant différents)
  double rayonContact = a.rayon_reel + b.rayon_reel; 
  
  if (distance < rayonContact) {
    double nx = dx / distance;
    double ny = dy / distance;
    
    double overlap = rayonContact - distance;
    a.x += nx * overlap / 2;
    a.y += ny * overlap / 2;
    b.x -= nx * overlap / 2;
    b.y -= ny * overlap / 2;
    
    double v1n = a.vx * nx + a.vy * ny;
    double v2n = b.vx * nx + b.vy * ny;
    
    if (v1n - v2n < 0) {
      double restitution = 0.8; 
      
      // Formule de choc avec MASSES DIFFÉRENTES
      double impulse = (-(1 + restitution) * (v1n - v2n)) / (1/a.m + 1/b.m);
      
      a.vx += (impulse / a.m) * nx;
      a.vy += (impulse / a.m) * ny;
      b.vx -= (impulse / b.m) * nx;
      b.vy -= (impulse / b.m) * ny;
      
      // La petite souffre plus du choc que la grosse (perte de rotation)
      a.omega_phi *= (a.scale < b.scale) ? 0.80 : 0.95;
      b.omega_phi *= (b.scale < a.scale) ? 0.80 : 0.95;
    }
  }
}

void mousePressed() {
  t1.lancer(-1);
  t2.lancer(1); 
}

void checkHUD() {
  camera(); hint(DISABLE_DEPTH_TEST);
  fill(255); textSize(16); textAlign(LEFT);
  text("Petite (Bleu): " + (int)t1.omega_phi + " rad/s " + (t1.estCouchee() ? "[Morte]" : ""), 20, 30);
  text("Large (Rouge): " + (int)t2.omega_phi + " rad/s " + (t2.estCouchee() ? "[Morte]" : ""), 20, 50);
  
  if (!t1.lancee && !t2.lancee) {
     textAlign(CENTER); textSize(24);
     text("CLIQUER POUR LANCER", width/2, height/2);
  }
  hint(ENABLE_DEPTH_TEST);
}

// -------------------------------------------------------
// CLASSE TOUPIE
// -------------------------------------------------------
class Toupie {
  double x, y, z;
  double vx, vy;
  double theta = 0.2;
  double phi = 0;
  double omega_phi = 0;
  double omega_theta = 0;
  boolean lancee = false;
  
  double scale;
  double m, L, C, A;
  float rayon_reel;
  
  double frot_air = 0.035;
  double frot_sol = 0.008;
  double frot_pointe = 0.8;
  
  double facteur_drive = 0.08; 
  double force_centri_const = 0.002;
  double seuil_critique = 20.0;
  
  color c;
  
  Toupie(double startX, double startY, color col, double s) {
    x = startX;
    y = startY;
    c = col;
    scale = s;
    
    // --- PHYSIQUE AJUSTÉE ---
    // La hauteur (L) reste FIXE pour que les disques soient au même niveau
    L = 50; 
    
    // Le rayon change selon l'échelle (Largeur)
    rayon_reel = (float)(20 * scale);
    
    // La masse augmente avec le carré de l'échelle (surface du disque)
    m = 1.0 * scale * scale; 
    
    // L'inertie (C) augmente énormément avec la largeur (r^2)
    // Une toupie large est très stable
    C = 10 * scale * scale * scale; 
    A = 5 * scale * scale;
  }
  
  boolean estCouchee() {
    return (theta >= PI/2 - 0.15);
  }
  
  void lancer(int direction) {
    lancee = true;
    x = direction * 150;
    y = random(-5, 5); 
    
    vx = -direction * 2.5; 
    vy = random(-0.5, 0.5);
    
    // La petite tourne très vite, la grosse un peu moins vite au départ (plus dure à lancer)
    omega_phi = 60 / Math.sqrt(scale); 
    
    theta = 0.3;
    omega_theta = 0;
  }
  
  void update() {
    if (!lancee) return;
    
    // Kill Switch
    if (omega_phi < 5.0 && !estCouchee()) {
       omega_phi *= 0.8; 
       theta += 0.05;    
       omega_theta += 0.5; 
    }
    
    double r = Math.sqrt(x*x + y*y);
    double angle_pos = Math.atan2(y, x);
    double angle_pente = Math.atan(2 * courbure * r);
    
    double F_rappel = -m * g * Math.sin(angle_pente);
    double F_centri = omega_phi * force_centri_const * m; 
    
    double force_tangentielle = 0;
    if (theta < PI/2 - 0.1) {
       force_tangentielle = omega_phi * Math.sin(theta) * facteur_drive * m;
    }

    double F_radial = F_rappel + F_centri;
    double ax = (F_radial * Math.cos(angle_pos)) / m;
    double ay = (F_radial * Math.sin(angle_pos)) / m;
    
    ax += (force_tangentielle * Math.cos(angle_pos + PI/2)) / m;
    ay += (force_tangentielle * Math.sin(angle_pos + PI/2)) / m;
    
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
    
    // Rotation
    double acc_theta = (m * g * L * Math.sin(theta) - A * omega_phi * omega_phi * Math.cos(theta) * Math.sin(theta)) / C;
    
    if (omega_phi < seuil_critique) {
       double faiblesse = (seuil_critique - omega_phi) / seuil_critique;
       acc_theta += 2.0 * faiblesse;
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
      theta = PI/2 - 0.1;
      omega_phi = 0;
      vx = 0; vy = 0;
    }
    phi += omega_phi * dt;
  }
  
  void display() {
    if (lancee || (!lancee && frameCount % 30 < 15)) { 
      pushMatrix();
      translate((float)x, (float)y, (float)z);
      
      float lift = (float)Math.sin(theta) * rayon_reel;
      // On retire 4.0 (hauteur pointe) sans multiplier par scale, car la hauteur est fixe
      if (lift < 4.0) lift = 0; else lift -= 4.0;
      translate(0, 0, lift);
      
      rotateZ((float)phi);   
      rotateY((float)theta); 
      
      // --- DESSIN SANS SCALE() GLOBAL ---
      // On dessine avec les vraies dimensions pour ne pas déformer la hauteur
      
      // Tige (Reste taille standard)
      pushMatrix();
      translate(0,0,(float) L);
      rotateX(PI);
      fill(100); 
      drawCone(4, (float)L, 10); 
      popMatrix();

      // Disque (Largeur = rayon_reel, Hauteur = 4 fixe)
      translate(0,0,(float) L);
      fill(c); 
      cylinder(rayon_reel, 4); 

      // Indicateur de rotation (Cube)
      fill(255,255,0);
      translate(rayon_reel - 5, 0, 2); // Placé sur le bord du disque
      box(5);
      popMatrix();
    }
  }
}

// --- FONCTIONS GRAPHIQUES ---
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
