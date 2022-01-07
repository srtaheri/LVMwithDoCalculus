(defun find-common-regulators (x y)
  (intersection
   (genes-regulating-gene x)
   (genes-regulating-gene y)
   :test #'fequal))

(defun find-mediators (x y)
  (intersection
   (genes-regulated-by-gene x)
   (genes-regulating-gene y)
   :test #'fequal))

(defun get-shielded-mediators (M U)
  (loop for mediator in M
     unless  (intersection U (genes-regulating-gene mediator) :test #'fequal)
     collect mediator))

(defun find-front-door (filename causes effects)
  ;; TODO:  start with regulator and search for front door.
  (tofile filename
	  (format t "Cause	Effect	Regulators	Mediators~%")
	  (loop for cause in causes
	     do (loop for effect in effects
	     for mediators = (find-mediators cause effect)
	     for regulators = (find-common-regulators cause effect)
	     for shielded-mediators = (get-shielded-mediators mediators regulators)
	     when (and shielded-mediators regulators)
	      do  (format t "~A	~A	~{~A~^ // ~}	~{~A~^ // ~}~%"
		       (get-frame-name cause)
		       (get-frame-name effect)
		       (mapcar #'get-frame-name regulators)
		       (mapcar #'get-frame-name shielded-mediators))))))


(defun get-regulatees  (causes)
  (remove-duplicates
   (loop for cause in causes
	 append (genes-regulated-by-gene cause))
   :test #'fequal))

(defun get-regulators (effects)
  (remove-duplicates
   (loop for effect in effects
	 append (genes-regulating-gene effect)
	 )
   :test #'fequal))

(defun find-causes-of-front-door (filename regulators mediators)
  ;; TODO:  start with regulator and search for front door.
  (tofile filename
	  (format t "Regulator	Mediator	Causes	Effects~%")
	  (loop for regulator in regulators
	     for regulatees = (genes-regulated-by-gene regulator)
	       when regulatees
	     do (loop for mediator in (set-difference mediators regulatees :test #'fequal)
		   for mediator-regulators = (genes-regulating-gene mediator)
		   for mediator-regulatees = (genes-regulated-by-gene mediator)
		   for causes = (intersection regulatees mediator-regulators :test #'fequal)
		   for cause-regulatees = (get-regulatees causes)
		   for effects = (set-difference
				  (intersection regulatees mediator-regulatees
						:test #'fequal)
				  cause-regulatees :test #'fequal)
	     when (and causes effects)
	      do  (format t "~A	~A	~{~A~^ // ~}	~{~A~^ // ~}~%"
		       (get-frame-name regulator)
		       (get-frame-name mediator)
		       (mapcar #'get-frame-name causes)
		       (mapcar #'get-frame-name effects)
		       )))))


(defun find-shielded-confounder (confoundee1 confoundee2 shielded)
  (remove-duplicates
   (loop for confounder in (intersection
			   (genes-regulating-gene confoundee1)
			   (genes-regulating-gene confoundee2)
			   :test #'fequal)
	unless (intersection (genes-regulated-by-gene confounder)
			     shielded :test #'fequal)
	  collect confounder)
  :test #'fequal))

(defun find-napkin-problem (filename)
  (tofile filename
	  (format t "R	U	V	W	X	Y~%")
	  (loop for W in (gcai '|Genes|)
		for Rs = (genes-regulated-by-gene W)
		when Rs
		  do (loop for R in Rs
			   for Xs = (genes-regulated-by-gene R)
			   when Xs
			     do (loop for X in Xs
				      for Ys = (genes-regulated-by-gene X)
				      when Ys
				      do (loop for Y in Ys
					   for Vs = (find-shielded-confounder W Y (list R X))
					   for Us = (find-shielded-confounder W X (list R Y))
					       for obs = (list R W X Y)
					       when (and R Us Vs W X Y
							 (<= 1 (length Us))
							 (<= 1 (length Vs))
							 (not (find-duplicates obs))
							 (not (intersection Us Vs :test #'fequal))
							 (not (intersection obs Vs :test #'fequal))
							 (not (intersection Us obs :test #'fequal)))
					   do (format t "~A	~{~A~^ // ~}	~{~A~^ // ~}	~A	~A	~A~%"
						      (get-frame-name R)
						      (mapcar #'get-frame-name Us)
						      (mapcar #'get-frame-name Vs)
						      (get-frame-name W)
						      (get-frame-name X)
						      (get-frame-name Y))))))))

(defun find-front-door-regulators-and-causes (filename mediators)
  ;; TODO:  start with regulator and search for front door.
  (tofile filename
	  (format t "Effect	Mediator	Causes	Regulators~%")
	  (loop for mediator in mediators
		do (loop for effect in (genes-regulated-by-gene mediator)
			 for causes = (genes-regulating-gene mediator)
			 for regulators = (set-difference
					   (intersection (get-regulators causes)
							 (genes-regulating-gene effect)
							 :test #'fequal)
					   (cons mediator causes)
					   :test #'fequal)
			 for true-causes = (intersection causes (get-regulatees regulators) :test #'fequal)
			 when (and true-causes regulators (<= 1 (length true-causes)) (<= 1 (length regulators)))
			 do (format t "~A	~A	~{~A~^ // ~}	~{~A~^ // ~}~%"
				    (get-frame-name effect)
				    (get-frame-name mediator)
				    (mapcar #'get-frame-name true-causes)
				    (mapcar #'get-frame-name regulators)
				    )))))

(defun get-shielded-mediators-of-regulator (M U)
  (set-difference
   M
   (genes-regulated-by-gene U)
   :test #'fequal))

(defun find-causes (U M)
  (intersection
   (genes-regulated-by-gene U)
   (genes-regulating-gene M)
   :test #'fequal))

(defun find-effects (U M)
  (intersection
   (genes-regulated-by-gene U)
   (genes-regulated-by-gene M)
   :test #'fequal))

(setq *regulators* (loop for gene in (gcai '|Genes|)
			 when (genes-regulated-by-gene gene)
			   collect gene))

(setq *mediators* (loop for gene in (gcai '|Genes|)
			when (and
			      (genes-regulated-by-gene gene)
			      (genes-regulating-gene gene))
			  collect gene))


(defun print-linear-regulators (filename)
  (tofile filename
	  (format t "TF	Target	Regulation~%")
	  (loop for tu in (get-class-all-instances '|Transcription-Units|)
		do (loop for activator in (direct-activators tu)
			 when (class-all-type-of-p '|Proteins| activator)

			   do (loop for tf in (genes-of-protein activator)
				    do (loop for gene in (transcription-unit-genes tu)
					     do (format t "~A	~A	~A~%"
							(get-slot-value tf 'accession-1)
							(get-slot-value gene 'accession-1)
							"+"))))
		   (loop for inhibitor in (direct-inhibitors tu)
						 when (class-all-type-of-p '|Proteins| inhibitor)
						   do (loop for tf in (genes-of-protein inhibitor)
							    do (loop for gene in (transcription-unit-genes tu)
								     do (format t "~A	~A	~A~%"
										(get-slot-value tf 'accession-1)
										(get-slot-value gene 'accession-1)
										"-")))))))
