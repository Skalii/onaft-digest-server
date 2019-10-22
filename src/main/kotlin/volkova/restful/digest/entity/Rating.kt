package volkova.restful.digest.entity


import com.fasterxml.jackson.annotation.JsonIgnoreProperties
import com.fasterxml.jackson.annotation.JsonProperty
import com.fasterxml.jackson.annotation.JsonPropertyOrder

import javax.persistence.Column
import javax.persistence.Entity
import javax.persistence.FetchType
import javax.persistence.GeneratedValue
import javax.persistence.GenerationType
import javax.persistence.Id
import javax.persistence.Index
import javax.persistence.OneToOne
import javax.persistence.SequenceGenerator
import javax.persistence.Table
import javax.validation.constraints.NotNull


@Entity(name = "Rating")
@JsonPropertyOrder(value = ["id_rating", "stars", "seen", "publication"])
@SequenceGenerator(
        name = "ratings_seq",
        sequenceName = "ratings_id_rating_seq",
        schema = "public",
        allocationSize = 1)
@Table(
        name = "ratings",
        schema = "public",
        indexes = [
            Index(name = "ratings_pkey",
                    columnList = "id_rating",
                    unique = true),
            Index(name = "ratings_id_rating_uindex",
                    columnList = "id_rating",
                    unique = true)])

data class Rating(

        @Column(name = "id_rating",
                nullable = false)
        @GeneratedValue(
                strategy = GenerationType.SEQUENCE,
                generator = "ratings_seq")
        @Id
        @get:JsonProperty(value = "id_rating")
        @NotNull
        val idKeyword: Int = 0,

        @Column(name = "stars",
                nullable = false)
        @get:JsonProperty(value = "stars")
        @NotNull
        val stars: Double = 0.0,

        @Column(name = "seen",
                nullable = false)
        @get:JsonProperty(value = "seen")
        @NotNull
        val seen: Int = 0

) {

    @JsonIgnoreProperties(value = ["rating"])
    @get:JsonProperty(value = "publication")
    @OneToOne(
            targetEntity = Publication::class,
            fetch = FetchType.EAGER,
            mappedBy = "rating")
    lateinit var publication: Publication

    constructor() : this(
            0,
            0.0,
            0

    )


    constructor(
            idKeyword: Int = 0,
            stars: Double = 0.0,
            seen: Int = 0,
            publication: Publication = Publication()
    ) : this(
            idKeyword,
            stars,
            seen
    ) {
        this.publication = publication
    }

}