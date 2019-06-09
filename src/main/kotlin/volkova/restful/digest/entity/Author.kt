package volkova.restful.digest.entity


import com.fasterxml.jackson.annotation.JsonIgnoreProperties
import com.fasterxml.jackson.annotation.JsonProperty
import com.fasterxml.jackson.annotation.JsonPropertyOrder

import javax.persistence.CascadeType
import javax.persistence.Column
import javax.persistence.Entity
import javax.persistence.ForeignKey
import javax.persistence.GeneratedValue
import javax.persistence.GenerationType
import javax.persistence.Id
import javax.persistence.Index
import javax.persistence.JoinColumn
import javax.persistence.JoinTable
import javax.persistence.ManyToMany
import javax.persistence.SequenceGenerator
import javax.persistence.Table

import javax.validation.constraints.NotNull


@Entity(name = "Author")
@JsonPropertyOrder(
        value = ["id_author", "first_name", "middle_name", "surname", "publications"])  // последователность
@SequenceGenerator(
        name = "authors_seq",
        sequenceName = "authors_id_author_seq",
        schema = "public",
        allocationSize = 1)
@Table(
        name = "authors",
        schema = "public",
        indexes = [
            Index(name = "authors_pkey",
                    columnList = "id_author",
                    unique = true),
            Index(name = "authors_id_author_uindex",
                    columnList = "id_author",
                    unique = true)])
data class Author(

        @Column(name = "id_author",
                nullable = false)
        @GeneratedValue(
                strategy = GenerationType.SEQUENCE,
                generator = "authors_seq")
        @Id
        @get:JsonProperty(value = "id_author") // как именуюется
        @NotNull
        val idAuthor: Int = 0,

        @Column(name = "first_name",
                nullable = false)
        @get:JsonProperty(value = "first_name")
        @NotNull
        val firstName: String = "",

        @Column(name = "middle_name")
        @get:JsonProperty(value = "middle_name")
        @NotNull
        val middleName: String = "",

        @Column(name = "surname",
                nullable = false)
        @get:JsonProperty(value = "surname")
        @NotNull
        val surname: String = ""

) {

    @JoinTable(
            name = "publications_authors",
            joinColumns = [JoinColumn(
                    name = "id_author",
                    nullable = false,
                    foreignKey = ForeignKey(name = "publications_authors_id_author_fk"))],
            inverseJoinColumns = [JoinColumn(
                    name = "id_publication",
                    nullable = false,
                    foreignKey = ForeignKey(name = "publications_publications_id_publication_fk"))])
    @JsonIgnoreProperties(value = ["author"])
    @get:JsonProperty(value = "publications")
    @ManyToMany(cascade = [CascadeType.ALL])
    lateinit var publications: MutableList<Publication>

    constructor() : this(
            0,
            "",
            "",
            ""
    )
}

